#!/usr/bin/env bash

#./caffe/cmake_build/install/bin/caffe \
#  test

CAFFEBINDIR=./caffe/cmake_build/install/bin
export LD_LIBRARY_PATH=./caffe/cmake_build/install/lib:$LD_LIBRARY_PATH

#time $CAFFEBINDIR/classification \
#  ./ResNet-152-deploy.prototxt \
#  ./ResNet-152-model.caffemodel \
#  ./ResNet_mean.binaryproto \
#  ./caffe/data/ilsvrc12/synset_words.txt \
#  /media/TB/Videos/dextro-benchmark/1442548671.15JAHM2OYKKP/image_00400.jpg # seal

#time $CAFFEBINDIR/classification \
#  ./ResNet-152-deploy.prototxt \
#  ./ResNet-152-model.caffemodel \
#  ./ResNet_mean.binaryproto \
#  ./caffe/data/ilsvrc12/synset_words.txt \
#  /media/TB/Videos/dextro-benchmark/1442548671.15JAHM2OYKKP/image_01555.jpg # skydivers + airplane

VIDBASEDIR=/media/TB/Videos/dextro-benchmark
TMPCLASSIFICATIONOUT=/tmp/classification_output.txt
TOPN=3 # should be <= 5

shopt -s nullglob
for f in $VIDBASEDIR/*/image_??[05]01.jpg
do
  echo Processing image=$f

  BASEFILE=${f##*/}
  VIDEOID=$(basename "$(dirname $f)")
  IMAGEID=${BASEFILE%.*}

  # run classification
  $CAFFEBINDIR/classification \
    ./ResNet-152-deploy.prototxt \
    ./ResNet-152-model.caffemodel \
    ./ResNet_mean.binaryproto \
    ./caffe/data/ilsvrc12/synset_words.txt \
    $f | egrep " - \"n" | head -$TOPN > $TMPCLASSIFICATIONOUT

  # detection output pretty-print
  #DETECTION=$(
  #            head -4 /tmp/classification_output.txt | \
  #            tail -n 2 | \
  #            tr '\n' ' '
  #            )
  DETECTION=""
  while read LINE; do
    # each LINE looks like: DETECTION=0.3556 - "n02111500 Great Pyrenees"
    PROB=$(echo $LINE | sed -e 's/DETECTION=//' -e 's/\ .*//')
    PROB=${PROB:2:2}.${PROB:4:1}
    CATEGORY=$(echo $LINE | sed -e 's/.*"n[0-9]*\ //' -e 's/"//')
    CATEGORY=${CATEGORY:0:40} # N characters at most
    echo PROB=$PROB, CATEGORY=$CATEGORY
    DETECTION="$DETECTION$CATEGORY (${PROB}\%)\n"
    echo DETECTION=$DETECTION
  done < $TMPCLASSIFICATIONOUT
  rm $TMPCLASSIFICATIONOUT

  # show detection
  DETECTION="${DETECTION%??}" # trim the last extra line break (\n)
  echo DETECTION=$DETECTION

  if [ -z "$DETECTION" ]; then
      echo "[warning] DETECTION is empty!"
  else
  # add a caption with the detection
  convert -background '#00000080' -fill white label:"$DETECTION" miff:- |\
    composite -gravity south -geometry +0+3 \
    - $f ${VIDEOID}_${IMAGEID}_result.jpg
  fi
done

# Usage: ./caffe/cmake_build/install/bin/classification deploy.prototxt network.caffemodel mean.binaryproto labels.txt img.jpg
#  Flags from /home/chuck/projects/deep-residual-networks/caffe/tools/caffe.cpp:
#    -gpu (Optional; run in GPU mode on given device IDs separated by ','.Use
#      '-gpu all' to run on all available GPUs. The effective training batch
#      size is multiplied by the number of devices.) type: string default: ""
#    -iterations (The number of iterations to run.) type: int32 default: 50
#    -model (The model definition protocol buffer text file..) type: string
#      default: ""
#    -sighup_effect (Optional; action to take when a SIGHUP signal is received:
#      snapshot, stop or none.) type: string default: "snapshot"
#    -sigint_effect (Optional; action to take when a SIGINT signal is received:
#      snapshot, stop or none.) type: string default: "stop"
#    -snapshot (Optional; the snapshot solver state to resume training.)
#      type: string default: ""
#    -solver (The solver definition protocol buffer text file.) type: string
#      default: ""
#    -weights (Optional; the pretrained weights to initialize finetuning,
#      separated by ','. Cannot be set simultaneously with snapshot.)
#      type: string default: ""

