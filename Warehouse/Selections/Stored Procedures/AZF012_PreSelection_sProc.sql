﻿-- =============================================
-- Author:  <Rory Francis>
-- Create date: <2021-05-15>
-- Description: < sProc to run preselection code per camapign >
-- =============================================
CREATE PROCEDURE [Selections].[AZF012_PreSelection_sProc]
AS
BEGIN

IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT CINID ,FanID
INTO #FB
FROM Relational.Customer C
JOIN Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE C.CurrentlyActive = 1
AND SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)
AND (PostCodeDistrict IN ('A00','AB10','AB11','AB12','AB13','AB14','AB15','AB16','AB21','AB22','AB23','AB24','AB25','AB32','AL1','AL10','AL2','AL3','AL4','AL5','AL6','AL7','AL8'
,'AL9','B1','B10','B11','B12','B13','B14','B15','B16','B17','B18','B19','B2','B20','B21','B23','B24','B25','B26','B27','B28','B29','B3','B30','B31','B32'
,'B33','B34','B35','B36','B37','B38','B4','B40','B42','B43','B44','B45','B46','B47','B48','B5','B6','B60','B61','B62','B63','B64','B65','B66','B67','B68'
,'B69','B7','B70','B71','B72','B73','B74','B75','B76','B77','B78','B79','B8','B80','B9','B90','B91','B92','B93','B94','B96','B97','B98','BB1','BB2','BB3'
,'BD1','BD10','BD11','BD12','BD13','BD14','BD15','BD16','BD17','BD18','BD19','BD2','BD21','BD22','BD3','BD4','BD5','BD6','BD7','BD8','BD9','BH24','BL0'
,'BL1','BL2','BL3','BL4','BL5','BL6','BL7','BL8','BL9','BN1','BN11','BN12','BN13','BN14','BN15','BN16','BN17','BN18','BN20','BN21','BN22','BN23','BN24'
,'BN25','BN26','BN27','BN3','BN41','BN42','BN43','BN44','BN9','BR5','BR7','BR8','BS1','BS10','BS11','BS15','BS16','BS2','BS20','BS21','BS22','BS23','BS24'
,'BS25','BS26','BS27','BS29','BS3','BS32','BS34','BS35','BS36','BS4','BS40','BS41','BS48','BS49','BS5','BS6','BS7','BS8','BS9','CB1','CB2','CB22','CB23'
,'CB24','CB3','CB4','CB5','CF10','CF11','CF14','CF15','CF23','CF24','CF3','CF31','CF32','CF33','CF34','CF35','CF36','CF37','CF38','CF5','CF72','CF82','CF83'
,'CH1','CH2','CH4','CH41','CH42','CH43','CH44','CH45','CH5','CH6','CH60','CH62','CH63','CH64','CH65','CH66','CM19','CO11','CR0','CR2','CR4','CR5','CR7','CR8'
,'CR9','CV1','CV10','CV11','CV12','CV2','CV21','CV22','CV23','CV3','CV31','CV32','CV33','CV34','CV35','CV4','CV47','CV5','CV6','CV7','CV8','CW11','CW3','CW5'
,'DA1','DA10','DA11','DA12','DA14','DA15','DA16','DA17','DA18','DA2','DA4','DA5','DA6','DA7','DA8','DA9','DD1','DD2','DD3','DD4','DD5','DE1','DE11','DE12'
,'DE21','DE22','DE23','DE24','DE3','DE5','DE55','DE56','DE65','DE7','DE72','DE73','DE74','DE75','DH1','DH2','DH3','DH4','DH5','DH6','DH7','DH9','DN1','DN11'
,'DN12','DN2','DN4','DN5','DY1','DY10','DY11','DY2','DY3','DY4','DY9','E1','E10','E11','E12','E13','E14','E15','E16','E17','E18','E1W','E2','E20','E3','E4'
,'E5','E6','E7','E8','E9','EC1A','EC1M','EC1N','EC1P','EC1R','EC1V','EC1Y','EC2A','EC2M','EC2N','EC2P','EC2R','EC2V','EC2Y','EC3A','EC3M','EC3N','EC3P','EC3R'
,'EC3V','EC4A','EC4M','EC4N','EC4P','EC4R','EC4V','EC4Y','EH1','EH10','EH11','EH12','EH13','EH14','EH15','EH16','EH17','EH18','EH19','EH2','EH20','EH21','EH22'
,'EH24','EH25','EH26','EH27','EH28','EH29','EH3','EH30','EH33','EH35','EH4','EH47','EH48','EH49','EH5','EH51','EH52','EH53','EH54','EH55','EH7','EH8','EH9','EN1'
,'EN10','EN11','EN2','EN3','EN4','EN5','EN6','EN7','EN8','EN9','EX1','EX2','EX4','EX5','FK10','FK11','FK12','FK13','FK3','FK4','FK5','FK6','FK7','FK9','FY1','FY2'
,'FY3','FY4','FY5','FY6','FY7','G1','G11','G12','G13','G14','G15','G2','G20','G21','G22','G23','G3','G31','G32','G33','G34','G4','G40','G41','G42','G43','G44','G45'
,'G46','G5','G51','G52','G53','G60','G61','G62','G64','G65','G66','G67','G68','G69','G71','G72','G73','G74','G75','G76','G77','G78','G79','G81','GL1','GL10','GL12'
,'GL13','GL17','GL18','GL19','GL2','GL20','GL3','GL4','GL5','GL50','GL51','GL52','GL53','GL7','GU1','GU10','GU11','GU12','GU14','GU15','GU16','GU17','GU18','GU19'
,'GU2','GU20','GU21','GU22','GU23','GU24','GU25','GU3','GU32','GU4','GU46','GU47','GU51','GU52','GU7','GU8','GU9','HA0','HA1','HA2','HA3','HA4','HA5','HA6','HA7'
,'HA8','HA9','HD1','HD2','HD3','HD5','HD6','HP1','HP11','HP12','HP13','HP2','HP23','HP3','HP4','HP5','HP6','HP8','HU1','HU10','HU13','HU14','HU15','HU16','HU17'
,'HU2','HU20','HU3','HU4','HU5','HU6','HU7','HU8','HU9','HX1','HX2','HX3','HX4','HX5','HX6','HX7','IG1','IG11','IG2','IG3','IG4','IG5','IP1','IP10','IP11','IP12'
,'IP14','IP2','IP3','IP30','IP4','IP5','IP6','IP7','IP8','IP9','KA1','KA10','KA11','KA12','KA13','KA14','KA15','KA2','KA20','KA21','KA22','KA23','KA24','KA25','KA29'
)
OR PostCodeDistrict IN ('KA3','KA4','KA7','KA8','KA9','KT1','KT10','KT11','KT12','KT13','KT14','KT15','KT16','KT17','KT18','KT19','KT2','KT20','KT21','KT22','KT24','KT3','KT4','KT5','KT6'
,'KT7','KT8','KT9','L1','L10','L11','L12','L13','L14','L15','L16','L17','L18','L19','L2','L20','L21','L22','L23','L24','L25','L26','L27','L28','L29','L3','L30','L31'
,'L32','L33','L34','L35','L36','L37','L38','L39','L4','L40','L5','L6','L69','L7','L8','L9','LE1','LE10','LE11','LE12','LE17','LE18','LE19','LE2','LE3','LE4','LE5'
,'LE6','LE65','LE67','LE8','LE9','LL11','LL12','LL13','LL14','LS1','LS10','LS11','LS12','LS13','LS14','LS15','LS16','LS17','LS18','LS19','LS2','LS20','LS24','LS25'
,'LS26','LS27','LS28','LS3','LS4','LS5','LS6','LS7','LS8','LS9','LU1','LU2','LU3','LU4','LU5','LU6','LU7','M1','M11','M12','M13','M14','M15','M16','M17','M18','M19'
,'M2','M20','M21','M22','M23','M24','M25','M26','M27','M28','M29','M3','M30','M31','M32','M33','M34','M35','M38','M4','M40','M41','M43','M44','M45','M46','M5','M50'
,'M6','M60','M7','M8','M9','M90','ME2','ME4','ME5','ME7','ME8','MK1','MK10','MK11','MK12','MK13','MK14','MK15','MK16','MK17','MK18','MK19','MK2','MK3','MK4','MK40'
,'MK41','MK42','MK45','MK46','MK5','MK6','MK7','MK8','MK9','ML1','ML2','ML3','ML4','ML5','ML6','ML9','N1','N10','N11','N12','N13','N14','N15','N16','N17','N18','N19'
,'N1C','N2','N20','N21','N22','N3','N4','N5','N6','N7','N8','N9','NE1','NE10','NE11','NE12','NE13','NE15','NE16','NE17','NE18','NE2','NE20','NE21','NE22','NE23','NE24'
,'NE25','NE26','NE27','NE28','NE29','NE3','NE30','NE31','NE32','NE33','NE34','NE35','NE36','NE37','NE38','NE39','NE4','NE40','NE41','NE42','NE43','NE44','NE45','NE5'
,'NE6','NE7','NE8','NE9','NG1','NG10','NG15','NG16','NG17','NG18','NG2','NG3','NG4','NG5','NG6','NG7','NG8','NG9','NN1','NN10','NN12','NN13','NN2','NN29','NN3','NN4'
,'NN5','NN6','NN7','NN8','NN9','NP10','NP11','NP20','NR1','NR13','NR14','NR15','NR17','NR18','NR2','NR3','NR4','NR5','NR6','NR7','NR8','NW1','NW10','NW11','NW2','NW3'
,'NW4','NW5','NW6','NW7','NW8','NW9','OL1','OL10','OL11','OL2','OL6','OL7','OL8','OL9','OX15','OX16','OX17','OX25','OX26','OX27','PA1','PA10','PA11','PA12','PA13'
,'PA14','PA2','PA3','PA4','PA5','PA6','PA7','PA8','PA9','PE1','PE19','PE2','PE26','PE27','PE29','PE3','PE4','PE5','PE6','PE7','PE8','PE9','PL1','PL12','PL2','PL21'
,'PL3','PL4','PL5','PL6','PL7','PL8','PL9','PO1','PO10','PO11','PO12','PO13','PO14','PO15','PO16','PO17','PO18','PO19','PO2','PO3','PO4','PO5','PO6','PO7','PO8','PO9'
,'PR1','PR2','PR25','PR26','PR4','PR5','PR6','PR7','RG1','RG10','RG12','RG2','RG21','RG22','RG23','RG24','RG25','RG26','RG27','RG28','RG29','RG30','RG31','RG4','RG40'
,'RG41','RG42','RG45','RG5','RG6','RG7','RG8','RM1','RM10','RM11','RM12','RM13','RM14','RM15','RM19','RM2','RM20','RM3','RM5','RM6','RM7','RM8','RM9','S1','S10','S11'
,'S12','S13','S14','S17','S18','S2','S20','S21','S25','S26','S3','S35','S4','S40','S41','S42','S43','S44','S5','S6','S60','S61','S62','S63','S64','S65','S66','S7'
,'S70','S71','S72','S73','S74','S75','S8','S80','S81','S9','SA1','SA10','SA11','SA12','SA13','SA5','SA6','SA7','SA8','SE1','SE10','SE11','SE12','SE13','SE14','SE15'
,'SE16','SE17','SE18','SE19','SE2','SE20','SE21','SE22','SE23','SE24','SE25','SE26','SE27','SE28','SE3','SE4','SE5','SE6','SE7','SE8','SE9','SG1','SG12','SG13','SG14'
,'SG15','SG16','SG17','SG18','SG19','SG2','SG3','SG4','SG5','SG6','SG7','SG8','SK1','SK14','SK15','SK16','SK2','SK3','SK4','SK5','SK6','SK7','SK8','SL5','SL9','SM1'
,'SM2','SM3','SM4','SM5','SM6','SM7','SN1','SN2','SN25','SN26','SN3','SN4','SN5','SN6','SN7','SN8','SO14','SO15','SO16','SO17','SO18','SO19','SO21','SO22','SO23'
,'SO30','SO31','SO32','SO40','SO43','SO50','SO51','SO52','SO53','SR1','SR2','SR3','SR4','SR5','SR6','SR7','SR8','SS0','SS12','SS13','SS14','SS15','SS16','SS6','SS7'
,'SS8','SS9','ST1','ST10','ST11','ST12','ST13','ST15','ST19','ST2','ST3','ST4','ST5','ST6','ST7','ST8','ST9','SW10','SW11','SW12','SW13','SW14','SW15','SW16','SW17'
,'SW18','SW19','SW1A','SW1E','SW1H','SW1P','SW1V','SW1W','SW1X','SW1Y','SW2','SW20','SW3','SW4','SW5','SW6','SW7','SW8','SW9','TA8','TA9','TN38','TN39','TN40','TQ10'
,'TW1','TW10','TW11','TW12','TW13','TW14','TW15','TW16','TW17','TW18','TW19','TW2','TW20','TW3','TW4','TW5','TW7','TW8','TW9','UB1','UB10','UB11','UB2','UB3','UB4'
,'UB5','UB6','UB7','UB8','UB9','W10','W11','W12','W13','W14','W1A','W1B','W1C','W1D','W1F','W1G','W1H','W1J','W1K','W1S','W1T','W1U','W1W','W2','W3','W4','W5','W6'
,'W7','W8','W9','WA1','WA10','WA11','WA12','WA13','WA14','WA15','WA2','WA3','WA4','WA5','WA7','WA8','WA9','WC1A','WC1B','WC1E','WC1H','WC1N','WC1R','WC1V','WC1X'
,'WC2A','WC2B','WC2E','WC2H','WC2N','WC2R','WD17','WD18','WD19','WD23','WD24','WD25','WD3','WD4','WD5','WD6','WD7','WF1','WF10','WF11','WF12','WF13','WF14','WF15'
,'WF16','WF17','WF2','WF3','WF5','WF6','WF7','WF8','WN1','WN2','WN3','WN4','WN5','WN6','WN7','WN8','WR1','WR3','WR4','WR5','WR7','WR9','WS1','WS10','WS11','WS12'
,'WS14','WS2','WS3','WS4','WS5','WS6','WS7','WS8','WS9','WV1','WV10','WV11','WV12','WV13','WV14','WV2','WV3','WV4','WV6','WV7','WV8','WV9','YO1','YO10','YO19'
,'YO23','YO24','YO26','YO30','YO31','YO32','YO41','YO42','YO90')
)

CREATE CLUSTERED INDEX IX_CINID ON #FB(CINID)


IF OBJECT_ID('Sandbox.RukanK.AmazonFresh_FullOpp_27102021') IS NOT NULL DROP TABLE Sandbox.RukanK.AmazonFresh_FullOpp_27102021
SELECT CINID
INTO Sandbox.RukanK.AmazonFresh_FullOpp_27102021
FROM #FB
GROUP BY CINID
				
If Object_ID('Warehouse.Selections.AZF012_PreSelection') Is Not Null Drop Table Warehouse.Selections.AZF012_PreSelection
Select FanID
Into Warehouse.Selections.AZF012_PreSelection
FROM #FB fb
WHERE EXISTS (	SELECT 1
				FROM Sandbox.RukanK.AmazonFresh_FullOpp_27102021 st
				WHERE fb.CINID = st.CINID)

END