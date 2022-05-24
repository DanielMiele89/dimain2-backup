CREATE TABLE [Relational].[GeoDemographicHeatMap_LookUp_Table] (
    [LookUpID]                    INT              IDENTITY (1, 1) NOT NULL,
    [PartnerID]                   INT              NOT NULL,
    [BrandID]                     INT              NOT NULL,
    [PartnerName]                 VARCHAR (200)    NOT NULL,
    [Partner_Flag]                BIT              NOT NULL,
    [Gender]                      CHAR (1)         NULL,
    [AgeGroup]                    VARCHAR (100)    NULL,
    [CAMEO_CODE_GRP]              VARCHAR (200)    NULL,
    [DriveTimeBand]               VARCHAR (50)     NULL,
    [Total_Brand_Spend]           MONEY            NULL,
    [Total_Brand_Spenders]        INT              NULL,
    [Total_Brand_Transactions]    INT              NULL,
    [Target_Spend_Prop]           DECIMAL (38, 14) NULL,
    [Base_Spend_Prop]             DECIMAL (38, 14) NULL,
    [SPC_Index]                   DECIMAL (38, 6)  NULL,
    [Response_Index]              DECIMAL (38, 6)  NULL,
    [Fixed_Total_Retail_Spenders] INT              NULL,
    [Calculation_RR]              DECIMAL (38, 6)  NULL,
    [Calculation_SPC]             DECIMAL (38, 6)  NULL,
    [Calculation_SPS]             DECIMAL (38, 6)  NULL,
    [Calculation_ATV]             DECIMAL (38, 6)  NULL,
    [Calculation_ATF]             DECIMAL (38, 6)  NULL,
    [Cardholders_By_Seg]          INT              NULL,
    [Percent_Spenders]            NUMERIC (24, 12) NULL,
    [Percent_Cardholders]         NUMERIC (24, 12) NULL,
    [PartnerSpend]                MONEY            NOT NULL,
    [PartnerSpenders]             INT              NOT NULL,
    [PartnerTrans]                INT              NOT NULL,
    [Response_Rank]               BIGINT           NULL,
    [Response_Rank2]              BIGINT           NULL,
    [ResponseIndexBand_ID]        INT              NULL,
    [Non_Spenders]                INT              NULL,
    [HeatMapID]                   INT              NULL,
    PRIMARY KEY CLUSTERED ([LookUpID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IDX_HeatMapID]
    ON [Relational].[GeoDemographicHeatMap_LookUp_Table]([HeatMapID] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_BrandID]
    ON [Relational].[GeoDemographicHeatMap_LookUp_Table]([BrandID] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_PartnerID]
    ON [Relational].[GeoDemographicHeatMap_LookUp_Table]([PartnerID] ASC);

