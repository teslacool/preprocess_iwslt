#!/usr/bin/env bash
set -e
set -x

CODES=10000
N_THREADS=24

srclng=en
tgtlng=$1
if [ -z $tgtlng ]; then
    echo "bash preprocess.sh tgtlng"
    exit
fi
if [ $tgtlng != "es" -a $tgtlng != 'zh' -a $tgtlng != 'ja' ]; then
    echo "unknown target language"
fi

MAIN_PATH=$PWD
TOOLS_PATH=$PWD/tools
DATA_PATH=$PWD/data/${srclng}_${tgtlng}
PARA_PATH=$DATA_PATH/para
PROC_PATH=$DATA_PATH/processed
mkdir -p $TOOLS_PATH
mkdir -p $DATA_PATH
mkdir -p $PARA_PATH
mkdir -p $PROC_PATH

MOSES=$TOOLS_PATH/mosesdecoder
REPLACE_UNICODE_PUNCT=$MOSES/scripts/tokenizer/replace-unicode-punctuation.perl
NORM_PUNC=$MOSES/scripts/tokenizer/normalize-punctuation.perl
REM_NON_PRINT_CHAR=$MOSES/scripts/tokenizer/remove-non-printing-char.perl
TOKENIZER=$MOSES/scripts/tokenizer/tokenizer.perl
FASTBPE_DIR=$TOOLS_PATH/fastBPE
FASTBPE=$TOOLS_PATH/fastBPE/fast

src_train_raw=$PARA_PATH/train.raw.$srclng
tgt_train_raw=$PARA_PATH/train.raw.$tgtlng
src_train_tok=$PARA_PATH/train.$srclng.tok
tgt_train_tok=$PARA_PATH/train.$tgtlng.tok
src_train_bpe=$PROC_PATH/train.$srclng
tgt_train_bpe=$PROC_PATH/train.$tgtlng
src_valid_raw=$PARA_PATH/valid.raw.$srclng
tgt_valid_raw=$PARA_PATH/valid.raw.$tgtlng
src_valid_tok=$PARA_PATH/valid.$srclng.tok
tgt_valid_tok=$PARA_PATH/valid.$tgtlng.tok
src_valid_bpe=$PROC_PATH/valid.$srclng
tgt_valid_bpe=$PROC_PATH/valid.$tgtlng
src_test_raw=$PARA_PATH/test.raw.$srclng
tgt_test_raw=$PARA_PATH/test.raw.$tgtlng
src_test_tok=$PARA_PATH/test.$srclng.tok
tgt_test_tok=$PARA_PATH/test.$tgtlng.tok
src_test_bpe=$PROC_PATH/test.$srclng
tgt_test_bpe=$PROC_PATH/test.$tgtlng
bpecodes=$PROC_PATH/codes

bash install-tools.sh
# download data
cd $PARA_PATH
train_url=https://wit3.fbk.eu/archive/2017-01-trnted//texts/en/$tgtlng/en-$tgtlng.tgz
test_url=https://wit3.fbk.eu/archive/2017-01-ted-test//texts/en/$tgtlng/en-$tgtlng.tgz
wget -c $train_url -O train-en-$tgtlng.tgz
wget -c $test_url  -O test-en-$tgtlng.tgz
if [ ! -d en-$tgtlng ]
then
    tar -xvzf train-en-$tgtlng.tgz
    tar -xvzf test-en-$tgtlng.tgz
fi
if [ ! -f $src_train_raw ]
then
    cp en-$tgtlng/train.tags.$srclng-$tgtlng.$srclng $src_train_raw
    cp en-$tgtlng/train.tags.$srclng-$tgtlng.$tgtlng $tgt_train_raw
fi
if [ ! -f $src_valid_raw ]
then
    cat en-$tgtlng/IWSLT17.TED.tst2013.$srclng-$tgtlng.$srclng.xml > $src_valid_raw
    cat en-$tgtlng/IWSLT17.TED.tst2014.$srclng-$tgtlng.$srclng.xml >> $src_valid_raw
    cat en-$tgtlng/IWSLT17.TED.tst2015.$srclng-$tgtlng.$srclng.xml >> $src_valid_raw
    cat en-$tgtlng/IWSLT17.TED.tst2013.$srclng-$tgtlng.$tgtlng.xml > $tgt_valid_raw
    cat en-$tgtlng/IWSLT17.TED.tst2014.$srclng-$tgtlng.$tgtlng.xml >> $tgt_valid_raw
    cat en-$tgtlng/IWSLT17.TED.tst2015.$srclng-$tgtlng.$tgtlng.xml >> $tgt_valid_raw
fi
if [ ! -f  $src_test_raw ]
then
    cp en-$tgtlng/IWSLT17.TED.tst2017.$srclng-$tgtlng.$srclng.xml $src_test_raw
fi


cd $MAIN_PATH
SRC_TRAIN_PREPROCESSING="grep -v '<url>' | grep -v '<speaker>' | grep -v '<reviewer' | grep -v '<translator' | grep -v '<doc docid' | grep -v '</doc>' | grep -v '<talkid>' | grep -v '<keywords>' | sed -e 's/<title>//g' | sed -e 's/<\/title>//g' | sed -e 's/<description>//g' | sed -e 's/<\/description>//g' "
SRC_TRAIN_PREPROCESSING="$SRC_TRAIN_PREPROCESSING | $REPLACE_UNICODE_PUNCT | $NORM_PUNC -l $srclng | $REM_NON_PRINT_CHAR | $TOKENIZER -l $srclng -no-escape -threads $N_THREADS"
TGT_TRAIN_PREPROCESSING="grep -v '<url>' | grep -v '<speaker>' | grep -v '<reviewer' | grep -v '<translator' | grep -v '<doc docid' | grep -v '</doc>' | grep -v '<talkid>' | grep -v '<keywords>' | sed -e 's/<title>//g' | sed -e 's/<\/title>//g' | sed -e 's/<description>//g' | sed -e 's/<\/description>//g' "
if [ $tgtlng == zh ]
then
TGT_TRAIN_PREPROCESSING="$TGT_TRAIN_PREPROCESSING  | $REM_NON_PRINT_CHAR | python zh_jieba.py "
else
TGT_TRAIN_PREPROCESSING="$TGT_TRAIN_PREPROCESSING | $REPLACE_UNICODE_PUNCT | $NORM_PUNC -l $tgtlng | $REM_NON_PRINT_CHAR | $TOKENIZER -l $tgtlng -no-escape -threads $N_THREADS"
fi

SRC_TEST_PREPROCESSING="grep '<seg id' | sed -e 's/<seg id=\"[0-9]*\">\s*//g' | sed -e 's/\s*<\/seg>\s*//g' | sed -e \"s/\’/\'/g\" "
SRC_TEST_PREPROCESSING="$SRC_TEST_PREPROCESSING | $REPLACE_UNICODE_PUNCT | $NORM_PUNC -l $srclng | $REM_NON_PRINT_CHAR | $TOKENIZER -l $srclng -no-escape -threads $N_THREADS"
TGT_TEST_PREPROCESSING="grep '<seg id' | sed -e 's/<seg id=\"[0-9]*\">\s*//g' | sed -e 's/\s*<\/seg>\s*//g'  "
if [ $tgtlng == zh ]
then
TGT_TEST_PREPROCESSING="$TGT_TEST_PREPROCESSING | $REM_NON_PRINT_CHAR | python zh_jieba.py "
else
TGT_TEST_PREPROCESSING="$TGT_TEST_PREPROCESSING | $REPLACE_UNICODE_PUNCT | $NORM_PUNC -l $tgtlng | $REM_NON_PRINT_CHAR | $TOKENIZER -l $tgtlng -no-escape -threads $N_THREADS"
fi
if [ ! -f $src_train_tok ]
then
    eval "cat $src_train_raw | $SRC_TRAIN_PREPROCESSING > $src_train_tok"
fi
if [ ! -f $tgt_train_tok ]
then
    eval "cat $tgt_train_raw | $TGT_TRAIN_PREPROCESSING > $tgt_train_tok"
fi

if [ ! -f $bpecodes ]
then
    if [ $tgtlng == 'zh' ]; then
        $FASTBPE learnbpe $CODES $src_train_tok > $bpecodes.$srclng
        $FASTBPE learnbpe $CODES $tgt_train_tok > $bpecodes.$tgtlng
    else
        $FASTBPE learnbpe $CODES  $src_train_tok $tgt_train_tok > $bpecodes
        cp $bpecodes $bpecodes.$srclng
        cp $bpecodes $bpecodes.$tgtlng
    fi
fi
if [ ! -f $src_train_bpe ]
then
    $FASTBPE applybpe $src_train_bpe $src_train_tok $bpecodes.$srclng
fi
if [ ! -f $tgt_train_bpe ]
then
    $FASTBPE applybpe $tgt_train_bpe $tgt_train_tok $bpecodes.$tgtlng
fi
if [ ! -f $src_test_bpe ]
then
    eval "cat $src_valid_raw | $SRC_TEST_PREPROCESSING > $src_valid_tok"
    $FASTBPE applybpe $src_valid_bpe $src_valid_tok $bpecodes.$srclng
    eval "cat $tgt_valid_raw | $TGT_TEST_PREPROCESSING > $tgt_valid_tok"
    $FASTBPE applybpe $tgt_valid_bpe $tgt_valid_tok $bpecodes.$tgtlng
    eval "cat $src_test_raw | $SRC_TEST_PREPROCESSING > $src_test_tok"
    $FASTBPE applybpe $src_test_bpe $src_test_tok $bpecodes.$srclng
fi
