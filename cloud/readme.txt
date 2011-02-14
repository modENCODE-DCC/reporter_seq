Introduction to modENCODE project

The National Human Genome Research Institute (NHGRI) model organism ENCyclopedia Of DNA Elements (modENCODE) Project will try to identify all of the sequence-based functional elements in the Caenorhabditis elegans and Drosophila melanogaster genomes. This project is described in Nature 2009 Jun 18;459(7249):927-30. 
modENCODE is run as a Research Network and data is publicly available, with some restrictions on its use for 9 months following publication.

modENCODE Data Coordinate Center (DCC) is led by Dr. Lincoln Stein. our role is to track the data, integrate it with other information sources, and make it available to the research community in a timely and open fashion. DCC provided following website from which community members can fetch information. they are:
major modENCODE website: http://www.modencode.org/
a portal to viewing all modENCODE data in Gbrowse: http://www.modencode.org/Genomes.shtml where the chromosome kayotype is clickable to bring you to Gbrowse.
a sophiscated integration tool of retriving data:
http://intermine.modencode.org/
 
there are other eleven research groups that generate data. they are:
1. transcriptome analysis on C. elegans, led by Dr. Robert Waterston. a brief description of their research goal can be found at: http://www.modencode.org/Waterston.shtml

2. chromatin function analysis on C. elegans, led by Dr. Jason Lieb. a brief description of their research goal can be found at: http://www.modencode.org/Lieb.shtml

3. Dr. Steven Henikoff works on both C. elegans and D. melanogaster. His research is focused on histone variants and nucleosome. a brief description of their research goal can be found at: http://www.modencode.org/Henikoff.shtml

4. Dr. Michael Snyder works on transcriptional factor binding profiling on C. elegans. a brief description of their research goal can be found at: http://www.modencode.org/Snyder.shtml

5. Dr. Fabio Piano lead his group research on 3' UTR of genes in C. elegan.  a brief description of their research goal can be found at: http://www.modencode.org/Piano.shtml

6. D. malanogaster transcriptome analysis is the research focus of Dr. Susan Celniker group. a brief description of their research goal can be found at: http://www.modencode.org/Celniker.shtml

7. Similar as what Dr. Michael Snyder do, Dr. Kevin White group focuses on transcriptional factor binding profiling on D. malanogaster. a brief description of their research goal can be found at: http://www.modencode.org/White.shtml

8. Dr. Gary Karpen lead the project of mapping chromosome proteins on the genome of D. malanogaster. a brief description of their research goal can be found at:
http://www.modencode.org/Karpen.shtml

9. Dr. Eric Lai lead the small and micro-RNA detection and annotation on the genome of fly. a brief description of their research goal can be found at:
http://www.modencode.org/Lai.shtml

10. Dr. David MacAlpine is interested in Replication Origins in Drosophila. a brief description of their research goal can be found at: http://www.modencode.org/MacAlpine.shtml

11. Dr. Brian Oliver lead his group working on cross-species validation of function of Drosophila transcriptome using comparative genomics method.  a brief description of their research goal can be found at: http://www.modencode.org/Oliver.shtml

cutting edge techniques are used by each individual group when they see best fit. At the very beginning of the project, most groups plan to use tiling array except for the group of Dr. Michael Snyder on worm transcriptional factor analysis using ChIp-seq. As time goes by, and mature of high thoroughput sequencing technology, quite a few projects switched to this new technology. Other tech, such as CAGE, RACE, CGH are also used and combined with either tiling array or sequencing. In a specific experiment, a technique used is called a protocol. DCC keeps a detailed description of every protocol for each experiment. a portal to these protocols could be: http://www.modencode.org/Protocols.shtml
you also could search the technique name at modMine by typing in the search box.

below is a list of technique used (as in examples):
CAGE as in submission 2549, 
http://wiki.modencode.org/project/index.php?title=CAGE_library_preparation:SC:1&oldid=26380
CAGE (Cap Analysis gene expression) is a technology commonly used to detect complext transcrptional start site (5-prime UTR). As a step to build rna-cdna library it could later combine with either capillary sequencing or high-thoroughput sequencing.

CGH or CNV-seq as in submission 3277,
http://intermine.modencode.org/release-21/objectDetails.do?id=935000110
Comparative Genome Hybridization is a typical method to study copy number variation in 


ChIP-chip as in submission 2585,
http://intermine.modencode.org/release-21/objectDetails.do?id=938000321

ChIP-seq as in submission 2429,
http://intermine.modencode.org/release-21/objectDetails.do?id=937000029


 
Processed File Formats

.GFF & .GFF3 
GFF = Generic Feature Format, and GFF3 is the most recent version. GFF3 files are plain text tab-delimited files used to represent genomic data. GFF3 files are commonly used to represent alignments, transcripts, genes, operons and numerous other features. There is a standardized format for columns, definitions and metadata that make a GFF3 file. More detailed information about GFF3 is available at
    • gmod.org/wiki/GFF3
    • www.sequenceontology.org/gff3.shtml


.bed format
BED = browser extendible display format. BED files are used to display genomic annotations in a track format. They have a minimum of 3 required fields for chromosome location and an additional 9 optional fields to customize the feature representation. More details about .bed format is available at 
http://genome.ucsc.edu/FAQ/FAQformat.html#format1

.wig format
WIG = wiggle track format. WIG files are used to display genomic data in a track format. WIG files are commonly used to display transcriptome data, GC percent and probability scores as values for a genomic position. More detailed information about WIG format files is available at
    • gmod.org/wiki/GBrowse/Uploading_Wiggle_Tracks
    • genome.ucsc.edu/goldenPath/help/wiggle.html


.sam format
SAM = Sequence Alignment Map. These files are used for mapping sequence reads to genomic co-ordinates. The sam format allows nucleotide sequences and the corresponding genomic location to which it maps for each line. More information about sam format can be found at 
http://samtools.sourceforge.net/

about Strain 
FlyStrain:7T-CAD:KW:1&oldid=24882
FlyStrain:Ago2_414:EL:1&oldid=27131
FlyStrain:B3:SH:1&oldid=24916
FlyStrain:Canton_S:EL:1&oldid=19988
FlyStrain:Dcr-2L811fsX&oldid=26678
FlyStrain:Dmojavensis:BO:1&oldid=31347
FlyStrain:D.pseudoobscura_wild-type:SC:1&oldid=31116
FlyStrain:EcR-GFP:KW:1&oldid=27423
FlyStrain:INV-GFP:KW:1&oldid=24493
FlyStrain:Loqs_f00791&oldid=15972
FlyStrain:Oregon-R:DM:1&oldid=17741
FlyStrain:Oregon-R:DM:1&oldid=24385
FlyStrain:Oregon-R_Orr-Weaver:DM:1&oldid=24391
FlyStrain:R13-YFP:KW:1&oldid=26590
FlyStrain:r2d2_1:EL:1&oldid=27133
FlyStrain:SENS-GFP:KW:1&oldid=24888
FlyStrain:w1118:DM:1&oldid=21818
FlyStrain:Y_cn_bw_sp&oldid=19925
Strain:N2&oldid=19052
WormStrain:11dh:JL:1&oldid=24299
WormStrain:BA1:FP:1&oldid=27254
WormStrain:BY200:RW:1&oldid=25131
WormStrain:CZ1200:RW:1&oldid=24283
WormStrain:daf-11(m47):FP:1&oldid=24970
WormStrain:daf-2(e1370):FP:1&oldid=24953
WormStrain:daf-7(e1372):FP:1&oldid=24956
WormStrain:daf-9(m540):FP:1&oldid=24958
WormStrain:DM8001:RW:1&oldid=25130
WormStrain:dpy28%28y1%29%3Bhim-8%28e1489%29&oldid=15979
WormStrain:dpy28(y1);him-8(e1489)&oldid=15979
WormStrain:GR1373:FP:1&oldid=27244
WormStrain:him-8(e1489):FP:1&oldid=24968
WormStrain:JJ2061:SH:1&oldid=25751
WormStrain:JK1107:RW:1&oldid=19877
WormStrain:JR1130:RW:1&oldid=25132
WormStrain:MES4FLAG:JL:1&oldid=24294
WormStrain:MT10430:RW:1&oldid=25192
WormStrain:MT17370:RW:1&oldid=27468
WormStrain:N2&oldid=19052
WormStrain:NC1021:RW:Miller&oldid=25408
WormStrain:NC1293:RW:1&oldid=27467
WormStrain:NC1598:RW:1&oldid=25402
WormStrain:NC1627:RW:1&oldid=25648
WormStrain:NC1668:RW:Miller&oldid=25405
WormStrain:NC1700:RW:1&oldid=25409
WormStrain:NC1749:RW:1&oldid=25098
WormStrain:NC1750:RW:1&oldid=33066
WormStrain:NC1790:RW:1&oldid=25411
WormStrain:NC1842:RW:1&oldid=25399
WormStrain:NC2015:RW:1&oldid=27607
WormStrain:NC300:RW:Miller&oldid=25133
WormStrain:NC694:RW:1&oldid=25372
WormStrain:NW1229:RW:1&oldid=25134
WormStrain:OP106:MS:1&oldid=27014
WormStrain:OP109:MS:1&oldid=27026
WormStrain:OP120:MS:1&oldid=27142
WormStrain:OP177:MS:1&oldid=27144
WormStrain:OP178:MS:1&oldid=27032
WormStrain:OP179:MS:1&oldid=25664
WormStrain:OP184:MS:1&oldid=27150
WormStrain:OP18:MS:1&oldid=24282
WormStrain:OP199:MS:1&oldid=27148
WormStrain:OP201:MS:1&oldid=27146
WormStrain:OP26:MS:1&oldid=24286
WormStrain:OP32:MS:1&oldid=21762
WormStrain:OP34:MS:1&oldid=24288
WormStrain:OP37:MS:1&oldid=24289
WormStrain:OP51:MS:1&oldid=27024
WormStrain:OP62:MS:1&oldid=25667
WormStrain:OP64:MS:1&oldid=25670
WormStrain:OP70:MS:1&oldid=27012
WormStrain:OP73:MS:1&oldid=22966
WormStrain:OP74:MS:1&oldid=25672
WormStrain:OP75:MS:1&oldid=27025
WormStrain:OP77:MS:1&oldid=25674
WormStrain:OP90:MS:1&oldid=25683
WormStrain:OS3991:RW:1&oldid=25412
WormStrain:PD4251:RW:1&oldid=25138
WormStrain:SD1075:RW:1&oldid=25400
WormStrain:SD1084:RW:1&oldid=25403
WormStrain:SD1241:RW:1&oldid=25404
WormStrain:spe-9(hc88)&oldid=15978
WormStrain:SS104:FP:1&oldid=27246
WormStrain:SS747:RW:1&oldid=25136
WormStrain:TJ356:MS:1&oldid=24292
WormStrain:TV1112:RW:1&oldid=25137
WormStrain:TX189:FP:1&oldid=25573
WormStrain:YPT41:JL:1&oldid=24296
WormStrain:YPT47:JL:1&oldid=21751

about cell line
CellLine:1182-4H:SC:1&oldid=13596
CellLine:CME-L1:SC:1&oldid=13923
CellLine:CME-W1-Cl.8%2B:SC:1&oldid=13924
CellLine:CME_W2:SC:1&oldid=13311
CellLine:Fly_biotin-tagged_H2A:SH:1&oldid=25506
CellLine:Fly_biotin-tagged_H2Av:SH:1&oldid=25505
CellLine:Fly_biotin-tagged_H3.3:SH:1&oldid=25508
CellLine:Fly_biotin-tagged_H3:SH:1&oldid=25510
CellLine:GM2:SC:1&oldid=13323
CellLine:Kc167:SC:1
CellLine:Kc167:SC:1&oldid=13327
CellLine:Kc-Rubin:EL:1&oldid=18941
CellLine:Mbn2:SC:1&oldid=13369
CellLine:ML-DmBG1-c1:SC:1&oldid=13331
CellLine:ML-DmBG2-c2:SC:1&oldid=13337
CellLine:ML-DmBG3-c2:SC:1
CellLine:ML-DmBG3-c2:SC:1&oldid=13333
CellLine:ML-DmD11:SC:1&oldid=13343
CellLine:ML-DmD16-c3:SC:1&oldid=13345
CellLine:ML-DmD17-c3:SC:1&oldid=13347
CellLine:ML-DmD20-c2:SC:1&oldid=13349
CellLine:ML-DmD20-c5:SC:1&oldid=13351
CellLine:ML-DmD21:SC:1&oldid=13353
CellLine:ML-DmD32:SC:1&oldid=13361
CellLine:ML-DmD4-c1:SC:1&oldid=13363
CellLine:ML-DmD8:SC:1&oldid=13365
CellLine:ML-DmD9:SC:1&oldid=13367
CellLine:OvarySomaticSheet:EL:1&oldid=26715
CellLine:S1:SC:1&oldid=13589
CellLine:S2-DRSC:SC:1
CellLine:S2-DRSC:SC:1&oldid=13590
CellLine:S2-NP:EL:1&oldid=27038
CellLine:S2R%2B:SC:1&oldid=13591
CellLine:S2-Rubin:EL:1&oldid=13375
CellLine:S2-Rubin:EL:1&oldid=18945
CellLine:S3:SC:1&oldid=13592
CellLine:Sg4:SC:1&oldid=17038


about tissue
Tissue:Adult_ovaries:EL:1&oldid=15639
Tissue:Adult_ovaries:EL:1&oldid=19323
Tissue:Adult_ovaries:EL:1&oldid=27128
Tissue:Adult_testis:EL:1&oldid=19324
Tissue:BAG_neurons_(embryonic):RW:1&oldid=27431
Tissue:body_wall_muscle:RW:1&oldid=23691
Tissue:CEPsh_(YA):RW:1&oldid=25174
Tissue:Coelomocytes_(L2):RW:1&oldid=25160
Tissue:coelomocytes:RW:1&oldid=23693
Tissue:Dmel_Female_heads:BO:1&oldid=31373
Tissue:Dmel_Male_heads:BO:1&oldid=31377
Tissue:Dmoj_Female_heads:BO:1&oldid=31352
Tissue:Dmoj_Male_heads:BO:1&oldid=31360
Tissue:dopaminergic_neurons_(embryonic):RW:1&oldid=23709
Tissue:Dopaminergic_neurons_(L3-L4):RW:1&oldid=25168
Tissue:Dpse_Female_heads:BO:1&oldid=31384
Tissue:Dpse_Male_heads:BO:1&oldid=31388
Tissue:embryo-AVA:RW:1&oldid=25141
Tissue:embryo-AVE:RW:1&oldid=33068
Tissue:Excretory_cell_(L2):RW:1&oldid=25154
Tissue:Female_body:EL:1&oldid=14272
Tissue:Female_body:EL:1&oldid=19981
Tissue:Female_heads:EL:1&oldid=19327
Tissue:Female_heads:EL:1&oldid=26965
Tissue:GABA_neurons_(embryonic):RW:1&oldid=22450
Tissue:GABA_neurons_(L2):RW:1&oldid=25150
Tissue:germ_line_precursor_(embryonic):RW:1&oldid=25116
Tissue:Glutamate_receptor_expressing_neurons_(L2):RW:1&oldid=25143
Tissue:Gonad:RW:1&oldid=19848
Tissue:Heads_OR:GK:1&oldid=26966
Tissue:hypodermis_(L3-L4):RW:1&oldid=25172
Tissue:hypodermis:RW:1&oldid=23699
Tissue:Imaginal_disc:EL:1&oldid=19328
Tissue:intestinal_cells:RW:1&oldid=23702
Tissue:Intestine_(L2):RW:1&oldid=25156
Tissue:L2-A-class:RW:1&oldid=25145
Tissue:Male_body:EL:1&oldid=19978
Tissue:Male_heads:EL:1&oldid=19331
Tissue:Pan-neural_(L2):RW:1&oldid=25158
Tissue:panneural:RW:1&oldid=23705
Tissue:pharyngeal_muscle:RW:1&oldid=27442
Tissue:PVC_neurons_(embryonic):RW:1&oldid=27437
Tissue:PVD_OLLs_(L3-L4):RW:1&oldid=25166
Tissue:reference_(early_embryo):RW:1&oldid=33071
Tissue:reference_(embryo):RW:1&oldid=23708
Tissue:reference_(L2):RW:1&oldid=25164
Tissue:reference_(L3-L4):RW:1&oldid=25170
Tissue:reference_(YA):RW:1&oldid=25176
Tissue:spermatids:FP:1&oldid=27252
Tissue:unc-4_neurons_(embryonic):RW:1&oldid=22442
Tissue:unfertilized_oocytes:FP:1&oldid=27257
Tissue:Whole_organism:EL:1&oldid=22975



about developmental stage
DevStage:0-2_day_old_pupae:EL:1&oldid=26221
DevStage:1st_instar_larvae:EL:1&oldid=19561
DevStage:2-4_day_old_pupae:EL:1&oldid=19977
DevStage:3rd_instar_larvae:EL:1&oldid=19967
DevStage:Adult_female,_eclosion_+_1_day:SC:1&oldid=19748
DevStage:Adult_female,_eclosion_+_30_days:SC:1&oldid=19603
DevStage:Adult_female,_eclosion_+_5_days:SC:1&oldid=19605
DevStage:Adult_Female:KW:1&oldid=15423
DevStage:Adult_male,_eclosion_+_1_day:SC:1&oldid=19608
DevStage:Adult_male,_eclosion_+_30_days:SC:1&oldid=19610
DevStage:Adult_male,_eclosion_+_5_days:SC:1&oldid=19612
DevStage:Adult_Male:KW:1&oldid=19570
DevStage:E0-4:KW:1&oldid=23066
DevStage:E12-16:KW:1&oldid=23068
DevStage:E16-20:KW:1&oldid=23062
DevStage:E20-24:KW:1&oldid=13293
DevStage:E20-24:KW:1&oldid=23064
DevStage:E4-8:KW:1&oldid=23065
DevStage:E8-12:KW:1&oldid=23069
DevStage:early_embryo:RW:Reinke&oldid=19885
DevStage:Embryo_0-12h:KW:1&oldid=13282
DevStage:Embryo_0-12h:KW:1&oldid=15420
DevStage:Embryo_0-12h:KW:1&oldid=24490
DevStage:Embryo_0-1h:EL:1&oldid=14283
DevStage:Embryo_0-4h:DM:1&oldid=22873
DevStage:Embryo_0-4h:DM:1&oldid=24375
DevStage:Embryo_10-12h:SC:1&oldid=19623
DevStage:Embryo_12-14h:SC:1&oldid=19630
DevStage:Embryo_12-24h:EL:1&oldid=19632
DevStage:Embryo_14-16h:SC:1&oldid=19640
DevStage:Embryo_16-18h:SC:1&oldid=19637
DevStage:Embryo_18-20h:SC:1&oldid=19635
DevStage:Embryo_20-22h:SC:1&oldid=19645
DevStage:Embryo_22-24hSC:1&oldid=19647
DevStage:Embryo_2-4h:SC:1&oldid=19643
DevStage:Embryo_2-6h:EL:1&oldid=14284
DevStage:Embryo_4-6h:SC:1&oldid=19649
DevStage:Embryo_6-10h:EL:1&oldid=19963
DevStage:Embryo_6-8h:SC:1&oldid=19658
DevStage:Embryo_8-10h:SC:1&oldid=19660
DevStageFly:0-1_day_old_pupae:EL:1&oldid=26223
DevStageFly:2-18hr_embryo:EL:1&oldid=30277
DevStageFly:3rd_Instar_Larvae:GK:1&oldid=23670
DevStageFly:Adult:EL:1&oldid=22056
DevStageFly:Adult_female_eclosion+4_day:SC:1&oldid=24519
DevStageFly:Adult_Female:EL:1&oldid=19944
DevStageFly:Adult_male:EL:1&oldid=19980
DevStageFly:DevStageFly:Pupae,_WPP_30-33h:KW:1&oldid=26807
DevStageFly:Dmel_Adult_Female_8_days:BO:1&oldid=32456
DevStageFly:Dmel_Adult_male_8_days:BO:1&oldid=32458
DevStageFly:Dmoj_Adult_Female:BO:1&oldid=31350
DevStageFly:Dmoj_Adult_Male:BO:1&oldid=31358
DevStageFly:Dpse_Adult_Female:BO:1&oldid=31382
DevStageFly:Dpse_Adult_Male:BO:1&oldid=31386
DevStageFly:E3-8h:KW:1&oldid=24482
DevStageFly:E7-24h:KW:1&oldid=24485
DevStageFly:Embryo_0-2h:SC:1&oldid=20054
DevStageFly:Embryo_0-8:KW:1&oldid=24486
DevStageFly:Embryo_14-16hr_OR:GK:1&oldid=23437
DevStageFly:Embryo_1-6h:KW:1&oldid=26594
DevStageFly:Embryo_2-4hr_OR:GK:1&oldid=23313
DevStageFly:Embryo_8-16h:KW:1&oldid=26603
DevStageFly:Mixed_Adult_7-11_day:SC:1&oldid=18687
DevStageFly:Mixed_Adult:GK:1&oldid=27623
DevStageFly:Pupae,_WPP_10-11h:KW:1&oldid=26804
DevStage:L1:KW:1&oldid=19704
DevStage:L1_stage_larvae:SC:1&oldid=19664
DevStage:L2:KW:1&oldid=23043
DevStage:L2_stage_larvae:SC:1&oldid=19666
DevStage:L3:KW:1&oldid=19707
DevStage:L3_stage_larvae,_12_hr_post-molt:SC:1&oldid=19668
DevStage:L3_stage_larvae,_clear_gut_PS(7-9)_stage:SC:1&oldid=20063
DevStage:L3_stage_larvae,_dark_blue_gut_PS(1-2)_stage:SC:1&oldid=19683
DevStage:L3_stage_larvae,_light_blue_gut_PS(3-6)_stage:SC:1&oldid=19685
DevStage:larva_mid-L1_25dC_4.0_hrs_post-L1:RW:Reinke&oldid=19714
DevStage:larva_mid-L2_25dC_17.75_hrs_post-L1:RW:Reinke&oldid=22298
DevStage:larva_mid-L3_25dC_26.75_hrs_post-L1:RW:Reinke&oldid=22366
DevStage:larva_mid-L4_25dC_34.25_hrs_post-L1:RW:Reinke&oldid=22306
DevStage:late_embryo_20dC_4.5_hrs_post-early_embryo:RW:Reinke&oldid=19886
DevStage:Lin-35(n745)_larva_mid-L1_25dC_4.0_hrs_post-L1:RW:Reinke&oldid=25193
DevStage:Male_larva_mid-L4_25dC_30_hrs_post-L1:RW:Reinke&oldid=17918
DevStage:mid-L1_20dC_4hrs_post-L1:RW:Slack&oldid=22160
DevStage:mid-L2_20dC_14hrs_post-L1:RW:Slack&oldid=22251
DevStage:mid-L3_20dC_25hrs_post-L1:RW:Slack&oldid=22252
DevStage:mid-L4_20dC_36hrs_post-L1:RW:Slack&oldid=22253
DevStage:Mixed_Embryos_0-24h:SC:1&oldid=19687
DevStage:Mixed_Population_Worms:FP:1&oldid=19422
DevStage:Mixed_stage_of_embryos_20dC:RW:Slack&oldid=22113
DevStage:Pupae:KW:1&oldid=19710
DevStage:Pupae,_WPP_+_2_days:SC:1&oldid=19690
DevStage:Pupae,_WPP_+_3_days:SC:1&oldid=19692
DevStage:Pupae,_WPP_+_4_days:SC:1&oldid=19695
DevStage:White_prepupae_(WPP):SC:1&oldid=19702
DevStageWorm:Adult_20dC_70hr_post-L1:FP:1&oldid=23283
DevStageWorm:Adult_23dC_12_days_post-L4:RW:1&oldid=27452
DevStageWorm:Adult_23dC_5_days_post-L4:RW:1&oldid=27450
DevStageWorm:Adult_males_20dC_70hr_post-L1:FP:1&oldid=24951
DevStageWorm:Adult_spe-9(hc88)_23dC_8_days_post-L4_molt:RW:1&oldid=22198
DevStageWorm:Adult_spe-9(hc88)_23dC_8_days_post-L4_molt:RW:1&oldid=27453
DevStageWorm:dauer_daf-2(el370)_25dC_91hrs_post-L1:RW:1&oldid=22180
DevStageWorm:dauer_entry_daf-2(el370)_25dC_48_hrs_post-L1:RW:1&oldid=25186
DevStageWorm:dauer_exit_daf-2(el370)_25dC_91hrs_15dC_12hrs_post-L1:RW:1&oldid=25188
DevStageWorm:Dauer_Larvae:FP:1&oldid=19596
DevStageWorm:Early_Embryo:JL:1&oldid=25201
DevStageWorm:embryo_him-8(e1480)_20dC:RW:1&oldid=22193
DevStageWorm:embryo:MS:1&oldid=19065
DevStageWorm:fed_L1:MS:1&oldid=20167
DevStageWorm:L1_20dC_8hr_post-L1:FP:1&oldid=23647
DevStageWorm:L2_20dC_20hr_post-L1:FP:1&oldid=23648
DevStageWorm:L2:MS:1&oldid=22953
DevStageWorm:L3_20dC_30hr_post-L1:FP:1&oldid=23649
DevStageWorm:L3-L4_larva_20dC_22h_23dC_24hr_post-L1:RW:1&oldid=25417
DevStageWorm:L3_Larva:JL:1&oldid=25204
DevStageWorm:L3:MS:1&oldid=19069
DevStageWorm:L4_20dC_45hr_post-L1:FP:1&oldid=23650
DevStageWorm:L4_Larva:JL:1&oldid=25207
DevStageWorm:L4:MS:1&oldid=24810
DevStageWorm:L4-Young_Adult:MS:1&oldid=19737
DevStageWorm:larva_mid-L2_20dC_22h_post-L1:RW:Miller&oldid=25392
DevStageWorm:late_embryo:MS:1&oldid=27008
DevStageWorm:Mass_spec:Shotgun_mixed_stage:RW:1&oldid=27336
DevStageWorm:Mixed_Embryo:JL:1&oldid=25198
DevStageWorm:Mixed_embryos_20dC:FP:1&oldid=23651
DevStageWorm:Older_embryos_(12-cell+_stage):FP:1&oldid=25592
DevStageWorm:one_cell_stage_embryos:FP:1&oldid=25583
DevStageWorm:post-gastrulation_embryos:FP:1&oldid=25586
DevStageWorm:starved_L1:MS:1&oldid=19067
DevStageWorm:two-to-four_cell_stage_embryos:FP:1&oldid=25580
DevStageWorm:Young_Adult_20dC_42_hrs_post-L1:RW:Reinke&oldid=22846
DevStageWorm:Young_Adult_20dC_72hr_post-L1:RW:Miller&oldid=25420
DevStageWorm:young_Adult_25dC:FP:1&oldid=27250
DevStageWorm:Young_Adult:MS:1&oldid=24812
DevStage:WPP_+_12_hr:SC:1&oldid=19698
DevStage:WPP_+_24_hr:SC:1&oldid=19700
DevStage:yAdult_20dC_48hrs_post-L1:RW:Slack&oldid=22255
DevStage:yAdult_23dC_DAY0post-L4_molt:RW:Slack&oldid=22257
DevStage:yAdult_Males_23dC:RW:Slack&oldid=22263
DevStage:Young_Adult_(pre-gravid)_25dC_46_hrs_post-L1:RW:Reinke&oldid=19474


about antibody
Ab:4H8:1&oldid=15986
Ab:8WG16:JL:CVMMS126R&oldid=21898
Ab:AB1791_H3_:JL:1&oldid=15750
Ab:ab4729_H3K27ac:361571:JL:1&oldid=26496
Ab:ab8895_H3K4me1:733246_:JL:1&oldid=26472
Ab:ab8896_H3K9me1:104560_:JL:1&oldid=26488
Ab:AB8898_H3K9ME3:339901:JL:1&oldid=23255
Ab:ab9045_H3K9me1:291918:JL:1&oldid=26485
Ab:ab9048_H3K36me1:206009_:JL:1&oldid=26505
Ab:AB9049_H3K36me2:608457:JL:1&oldid=23224
Ab:AB9050_H3K36ME3:JL:1&oldid=15751
Ab:ab9051_H4K20me1:104513_:JL:1&oldid=26554
Ab:ABAB817_8WG16:JL:1&oldid=22455
Ab:Ab:HDAC11-495:KW:1:KW:1&oldid=26397
Ab:Ab:HDAC11-495:KW:1:KW:1&oldid=35854
Ab:AGO1:EL:1&oldid=26684
Ab:Anti-eGFP:MS:1&oldid=17974
Ab:Anti-HA-Peroxidase:EL:1&oldid=24444
Ab:AR0144_H3:144:JL:1&oldid=22921
Ab:AR0169_H3K4ME3:JL:1&oldid=15752
Ab:ASH1_Q4177:GK:1&oldid=30637
Ab:bab1:KW:1&oldid=24135
Ab:BEAF-32:KW:1&oldid=23625
Ab:BEAF-70:GK:1&oldid=23527
Ab:BEAF-HB:GK:1&oldid=23550
Ab:bks:KW:1&oldid=24139
Ab:BRE1_Q2539:GK:1&oldid=23505
Ab:brm:KW:1&oldid=24147
Ab:cad-JR:KW:1&oldid=26469
Ab:CBP:KW:1&oldid=19082
Ab:CBP:KW:1&oldid=23623
Ab:chinmo:KW:1&oldid=23997
Ab:Chro(Chriz)BR:GK:1&oldid=23509
Ab:Chro(Chriz)WR:GK:1&oldid=23531
Ab:CNC:KW:1&oldid=23627
Ab:CP190-HB:GK:1&oldid=23482
Ab:CP190:KW:1&oldid=13513
Ab:CP190-VC:GK:1&oldid=23453
Ab:CTCF-C:KW:1&oldid=23631
Ab:CTCF-N:KW:1&oldid=23633
Ab:CTCF-VC:GK:1&oldid=23573
Ab:dCtBP7667:KW:1&oldid=24121
Ab:D-D2:KW:1&oldid=26451
Ab:disco-D2:KW:1&oldid=26454
Ab:D:KW:1&oldid=23724
Ab:dll:KW:1&oldid=24137
Ab:dMi-2_Q2626:GK:1&oldid=23441
Ab:dORC2:DM:1&oldid=17635
Ab:DPY26:JL:1&oldid=21711
Ab:DPY-27:JL:1&oldid=22236
Ab:dRING_Q3200:GK:1&oldid=23445
Ab:end300:KW:1&oldid=23991
Ab:ENserum:KW:1&oldid=23993
Ab:E(z)-D2:KW:1&oldid=26600
Ab:Ez:GK:1&oldid=23576
Ab:Ez:GK:1&oldid=26933
Ab:FLAG-Agarose_beads:RW:1&oldid=25397
Ab:FTZ-F1:KW:1&oldid=24127
Ab:GAF:GK:1&oldid=23554
Ab:GAF:KW:1&oldid=23639
Ab:GATAe-D1:KW:1&oldid=26457
Ab:GFP:KW:1&oldid=23765
Ab:GRO3:KW:1&oldid=24164
Ab:GROAviva:KW:1&oldid=23793
Ab:gsbnpurif:KW:1&oldid=24125
Ab:H2B-ubiq_(NRO3):GK:1&oldid=23473
Ab:H3K18ac:GK:1&oldid=23523
Ab:H3K18Ac_(new_lot):GK:1&oldid=23544
Ab:H3K23ac:GK:1&oldid=23479
Ab:H3K27Ac:GK:1&oldid=23469
Ab:H3K27Ac:KW:1&oldid=21948
Ab:H3K27Ac:KW:1&oldid=29343
Ab:H3K27Me3_(Abcam2):GK:1&oldid=23606
Ab:H3K27me3:KW:1&oldid=21946
Ab:H3K36me1:GK:1&oldid=23571
Ab:H3K36me3:GK:1&oldid=23456
Ab:H3K36me3:KW:1&oldid=23856
Ab:H3K4me1:GK:1&oldid=23491
Ab:H3K4me1:KW:1&oldid=21943
Ab:H3K4me1_(new_lot):GK:1&oldid=26938
Ab:H3K4me2:GK:1&oldid=23612
Ab:H3K4me2-Millipore:GK:1&oldid=26950
Ab:H3K4me3_(ab8580_lot1):GK:1&oldid=23538
Ab:H3K4me3:KW:1&oldid=21950
Ab:H3K4me3:KW:1&oldid=23859
Ab:H3K4Me3(LP):GK:1&oldid=23462
Ab:H3K79Me1:GK:1&oldid=23476
Ab:H3K79Me2:GK:1&oldid=23609
Ab:H3K79Me2:JL:1&oldid=24712
Ab:H3K79Me3:JL:1&oldid=24715
Ab:H3K9ac:GK:1&oldid=23587
Ab:H3K9Ac:KW:1&oldid=21952
Ab:H3K9acS10P_(new_lot):GK:1&oldid=26955
Ab:H3K9me2-Ab2_(new_lot):GK:1&oldid=23494
Ab:H3K9me2_antibody2:GK:1&oldid=23590
Ab:H3K9me3:GK:1&oldid=23557
Ab:H3K9me3:KW:1&oldid=21954
Ab:H3K9me3:KW:1&oldid=23858
Ab:H3K9me3_(new_lot):GK:1&oldid=23535
Ab:H4AcTetra:GK:1&oldid=23603
Ab:H4:GK:1&oldid=27461
Ab:H4K16ac(L):GK:1&oldid=23488
Ab:H4K16ac(M):GK:1&oldid=23566
Ab:H4K5ac:GK:1&oldid=23541
Ab:H4K8ac:GK:1&oldid=23583
Ab:h-D1:KW:1&oldid=26460
Ab:HDAC11-494:KW:1&oldid=26394
Ab:HDAC11-494:KW:1&oldid=35829
Ab:HDAC1-500:KW:1&oldid=26412
Ab:HDAC1-500:KW:1&oldid=35830
Ab:HDAC1-501:KW:1&oldid=26415
Ab:HDAC1-501:KW:1&oldid=35825
Ab:HDAC3-498:KW:1&oldid=26406
Ab:HDAC3-498:KW:1&oldid=35828
Ab:HDAC3-499:KW:1&oldid=26409
Ab:HDAC3-499:KW:1&oldid=35827
Ab:HDAC4a-492:KW:1&oldid=26387
Ab:HDAC4a-492:KW:1&oldid=35826
Ab:HDAC4a-493:KW:1&oldid=26390
Ab:HDAC4a-493:KW:1&oldid=35835
Ab:HDAC6-496:KW:1&oldid=26400
Ab:HDAC6-496:KW:1&oldid=35855
Ab:HDAC6-497:KW:1&oldid=26403
Ab:HDAC6-497:KW:1&oldid=35843
Ab:HK00001_H3K36me3:13C9:JL:1&oldid=23244
Ab:HK00008_H3K9me2:6D11:JL:1&oldid=23261
Ab:HK00009_H3K9me3:2F3:JL:1&oldid=23251
Ab:HK00012_H3K36me2:2C3:JL:1&oldid=23245
Ab:HK00013_H3K27me3:1E7:JL:1&oldid=24512
Ab:hkb-D1:KW:1&oldid=26463
Ab:HP1a_wa184:GK:1&oldid=26942
Ab:HP1b_(Henikoff):GK:1&oldid=23547
Ab:HP1c_(MO_462):GK:1&oldid=23580
Ab:HP1_wa191:GK:1&oldid=23675
Ab:HP2_(Ab2-90):GK:1&oldid=23600
Ab:HTZ-1:JL:BK0001&oldid=26722
Ab:INV7657:KW:1&oldid=23791
Ab:INV-GFP:KW:1&oldid=24167
Ab:JA00002_IGG:JL:1&oldid=15753
Ab:JIL1_Q3433:GK:1&oldid=23560
Ab:JL00001_DPY27:JL:1&oldid=21712
Ab:JL00002_SDC3:JL:1&oldid=21713
Ab:JL00012_DPY28:JL:1&oldid=21717
Ab:JL0004_MIX1:JL:1&oldid=21714
Ab:JL0005_SDC2:JL:1&oldid=21715
Ab:jumu-D2:KW:1&oldid=26466
Ab:KN:KW:1&oldid=23774
Ab:Kr-D2:KW:1&oldid=23777
Ab:LPAR109_H4tetraac:109_:JL:1&oldid=26551
Ab:MBD-R2_Q2567:GK:1&oldid=23450
Ab:MCM2-7:DM:1&oldid=18768
Ab:mod2.2-VC:GK:1&oldid=23485
Ab:mod%28mdg4%29:KW:1&oldid=23797
Ab:mod(mdg4)-D2:KW:1&oldid=26597
Ab:No_Antibody_Control:1&oldid=17462
Ab:NURF301_Q2602:GK:1&oldid=23520
Ab:OD00001_HCP3:JL:1&oldid=26760
Ab:OD00079_HCP3:JL:1&oldid=26126
Ab:Pc:GK:1&oldid=23465
Ab:PCL_Q3412:GK:1&oldid=23516
Ab:PIWI-Q2569:GK:1&oldid=23563
Ab:PolII:KW:1&oldid=21956
Ab:RNA_pol_II_(ALG):GK:1&oldid=23459
Ab:RNA_Polymerase_II:MS:1&oldid=19074
Ab:RUN7659:KW:1&oldid=23783
Ab:SDC-3:JL:1&oldid=22286
Ab:SDQ0790_MRG1:JL:1&oldid=22922
Ab:SDQ0791_MES4:JL:1&oldid=22923
Ab:SDQ3146_SDC2:JL:1&oldid=21720
Ab:SDQ3582_CBP1:JL:1&oldid=27185
Ab:SDQ3891_LEM2:JL:1&oldid=27040
Ab:SDQ4094_NPP13:JL:1&oldid=27047
Ab:sens:KW:1&oldid=23768
Ab:SGF3165_FLAG:JL:1&oldid=15804
Ab:snr1:KW:1&oldid=24149
Ab:SS00050_IGG:JL:1&oldid=22924
Ab:Stat92E:KW:1&oldid=23995
Ab:SU(HW)-HB:GK:1&oldid=23570
Ab:Su(Hw):KW:1&oldid=23798
Ab:Su(Hw)-PG:KW:1&oldid=24883
Ab:Su(Hw)-VC:GK:1&oldid=23597
Ab:Su(var)3-7-Q3448:GK:1&oldid=26945
Ab:Su(var)3-9:GK:1&oldid=23513
Ab:Trl-D2:KW:1&oldid=26384
Ab:Trx-C:GK:1&oldid=23501
Ab:TTK:KW:1&oldid=23785
Ab:UBX1:KW:1&oldid=24129
Ab:UBX2:KW:1&oldid=24131
Ab:UBX7701:KW:1&oldid=23787
Ab:UP07442_H3K9ME3:JL:1&oldid=15754
Ab:WA305-34819_H3K4me3:JL:1&oldid=23243
Ab:WA306-34849_H3K27ac:JL:1&oldid=26493
Ab:WA308-34809_H3K4me2:JL:1&oldid=23258
Ab:WDS_Q2691:GK:1&oldid=23619
Ab:ZFH1:KW:1&oldid=23789
Ab:ZW5:GK:1&oldid=31878
