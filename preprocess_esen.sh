#!/usr/bin/env bash
set -e
set -x

CODES=10000
N_THREADS=24

srclng=en
tgtlng=es

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
train_url=https://wit3.fbk.eu/archive/2014-01//texts/en/es/en-es.tgz
test_url1=https://wit3.fbk.eu/archive/2014-01-test//texts/es/en/es-en.tgz
test_url2=https://wit3.fbk.eu/archive/2014-01-test//texts/en/es/en-es.tgz
wget -c $train_url -O train-en-$tgtlng.tgz
wget -c $test_url1 -O test-es-en.tgz
wget -c $test_url2 -O test-en-es.tgz
if [ ! -d en-$tgtlng ]
then
    tar -xvzf train-en-$tgtlng.tgz
    tar -xvzf test-en-$tgtlng.tgz
fi
if [ ! -d es-en ]
then
    tar -xvzf test-es-en.tgz
fi
if [ ! -f $src_train_raw ]
then
    cp en-$tgtlng/train.tags.$srclng-$tgtlng.$srclng $src_train_raw
    cp en-$tgtlng/train.tags.$srclng-$tgtlng.$tgtlng $tgt_train_raw
fi
if [ ! -f $src_valid_raw ]
then
    cat en-$tgtlng/IWSLT14.TED.tst2010.$srclng-$tgtlng.$srclng.xml > $src_valid_raw
    cat en-$tgtlng/IWSLT14.TED.tst2011.$srclng-$tgtlng.$srclng.xml >> $src_valid_raw
    cat en-$tgtlng/IWSLT14.TED.tst2012.$srclng-$tgtlng.$srclng.xml >> $src_valid_raw
    cat en-$tgtlng/IWSLT14.TED.tst2010.$srclng-$tgtlng.$tgtlng.xml > $tgt_valid_raw
    cat en-$tgtlng/IWSLT14.TED.tst2011.$srclng-$tgtlng.$tgtlng.xml >> $tgt_valid_raw
    cat en-$tgtlng/IWSLT14.TED.tst2012.$srclng-$tgtlng.$tgtlng.xml >> $tgt_valid_raw
fi
if [ ! -f  $src_test_raw ]
then
    cp en-$tgtlng/IWSLT14.TED.tst2014.$srclng-$tgtlng.$srclng.xml $src_test_raw
    cp en-$tgtlng/IWSLT14.TED.tst2014.$srclng-$tgtlng.$tgtlng.xml $tgt_test_raw
fi


cd $MAIN_PATH
SRC_TRAIN_PREPROCESSING="grep -v '<url>' | grep -v '<speaker>' | grep -v '<reviewer' | grep -v '<translator' | grep -v '<doc docid' | grep -v '</doc>' | grep -v '<talkid>' | grep -v '<keywords>' | sed -e 's/<title>//g' | sed -e 's/<\/title>//g' | sed -e 's/<description>//g' | sed -e 's/<\/description>//g' "
SRC_TRAIN_PREPROCESSING="$SRC_TRAIN_PREPROCESSING | $REPLACE_UNICODE_PUNCT | $NORM_PUNC -l $srclng | $REM_NON_PRINT_CHAR | $TOKENIZER -l $srclng -no-escape -threads $N_THREADS"
TGT_TRAIN_PREPROCESSING="grep -v '<url>' | grep -v '<speaker>' | grep -v '<reviewer' | grep -v '<translator' | grep -v '<doc docid' | grep -v '</doc>' | grep -v '<talkid>' | grep -v '<keywords>' | sed -e 's/<title>//g' | sed -e 's/<\/title>//g' | sed -e 's/<description>//g' | sed -e 's/<\/description>//g' "
TGT_TRAIN_PREPROCESSING="$TGT_TRAIN_PREPROCESSING | $REPLACE_UNICODE_PUNCT | $NORM_PUNC -l $tgtlng | $REM_NON_PRINT_CHAR | $TOKENIZER -l $tgtlng -no-escape -threads $N_THREADS"
SRC_TEST_PREPROCESSING="grep '<seg id' | sed -e 's/<seg id=\"[0-9]*\">\s*//g' | sed -e 's/\s*<\/seg>\s*//g' | sed -e \"s/\’/\'/g\" "
SRC_TEST_PREPROCESSING="$SRC_TEST_PREPROCESSING | $REPLACE_UNICODE_PUNCT | $NORM_PUNC -l $srclng | $REM_NON_PRINT_CHAR | $TOKENIZER -l $srclng -no-escape -threads $N_THREADS"
TGT_TEST_PREPROCESSING="grep '<seg id' | sed -e 's/<seg id=\"[0-9]*\">\s*//g' | sed -e 's/\s*<\/seg>\s*//g' | sed -e \"s/\’/\'/g\" "
TGT_TEST_PREPROCESSING="$TGT_TEST_PREPROCESSING | $REPLACE_UNICODE_PUNCT | $NORM_PUNC -l $tgtlng | $REM_NON_PRINT_CHAR | $TOKENIZER -l $tgtlng -no-escape -threads $N_THREADS"
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
    $FASTBPE learnbpe $CODES  $src_train_tok $tgt_train_tok > $bpecodes
fi
if [ ! -f $src_train_bpe ]
then
    $FASTBPE applybpe $src_train_bpe $src_train_tok $bpecodes
fi
if [ ! -f $tgt_train_bpe ]
then
    $FASTBPE applybpe $tgt_train_bpe $tgt_train_tok $bpecodes
fi
if [ ! -f $src_test_bpe ]
then
    eval "cat $src_valid_raw | $SRC_TEST_PREPROCESSING > $src_valid_tok"
    $FASTBPE applybpe $src_valid_bpe $src_valid_tok $bpecodes
    eval "cat $tgt_valid_raw | $TGT_TEST_PREPROCESSING > $tgt_valid_tok"
    $FASTBPE applybpe $tgt_valid_bpe $tgt_valid_tok $bpecodes
    eval "cat $src_test_raw | $SRC_TEST_PREPROCESSING > $src_test_tok"
    $FASTBPE applybpe $src_test_bpe $src_test_tok $bpecodes
    eval "cat $tgt_test_raw | $TGT_TEST_PREPROCESSING > $tgt_test_tok"
    $FASTBPE applybpe $tgt_test_bpe $tgt_test_tok $bpecodes
fi
