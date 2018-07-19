#!/bin/sh


cd ../etc/
python clean_frame_metadata_logs.py

cd ../bin
./start_kafka_server.sh
wait

cd ../etc/
python clean_and_clear_topics.py

cd ../projects/ObjectDetection/
python FrameLabeling.py --model "../../res/MobileNetSSD_deploy.caffemodel" \
                        --model_prototxt "../../res/MobileNetSSD_deploy.prototxt.txt" \
                        --labels "../../res/labels.txt" \
                        --topic_name_in "general" &
                        
gnome-terminal -e "tail -f -n 0 ../../logs/FrameLabeling.log" &
                        

python GeneralObjDetection.py --model "../../res/MobileNetSSD_deploy.caffemodel" \
                              --model_prototxt "../../res/MobileNetSSD_deploy.prototxt.txt" \
                              --labels "../../res/labels.txt" \
                              --topic_name_in "target2" \
                              --topic_name_out "general" &
                              
gnome-terminal -e "tail -f -n 0 ../../logs/GeneralObjectDetection.log" &
                              
                              
#python GeneralObjDetectionYOLO.py --net "cfg/yolov3-tiny.cfg" \
                                  #--weights "yolov3-tiny.weights" \
                                  #--meta "cfg/coco.data" \
                                  #--topic_name_in "target2" \
                                  #--topic_name_out "general" &

python TargettedObjectDetectionProcess.py --graph "../../res/TfModel/output_graph.pb" \
                                          --labels "../../res/TfModel/output_labels.txt" \
                                          --input_layer "Placeholder" \
                                          --output_layer "final_result" \
                                          --input_height 224 \
                                          --input_width 224 \
                                          --topic_name_in "framefeeder" \
                                          --topic_name_out "target2" &
                                    
gnome-terminal -e "tail -f -n 0 ../../logs/TargettedObjectDetection.log" &
                                          

cd ../ETL/
python ETLProcess.py --video "../../res/Videos/vid.mp4" \
                     --topic_name_out "framefeeder" &
                     
gnome-terminal -e "tail -f -n 0 ../../logs/ETL.log"



#cd ../../etc/
#python clean-pyc.py


