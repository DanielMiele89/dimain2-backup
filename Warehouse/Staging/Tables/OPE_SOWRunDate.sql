CREATE TABLE [Staging].[OPE_SOWRunDate] (
    [PartnerID]            INT           NOT NULL,
    [PartnerName]          VARCHAR (100) NULL,
    [BrandID]              INT           NULL,
    [BrandName]            VARCHAR (100) NULL,
    [Mth]                  TINYINT       NULL,
    [PartnerName_Formated] VARCHAR (200) NULL,
    [LastRun]              DATETIME      NULL,
    [StartDate]            DATE          NULL,
    [EndDate]              DATE          NULL,
    [RowNo]                BIGINT        NULL
);

