CREATE TABLE [dbo].[MFDDRetailerTEST_KC] (
    [EarningSourceID] SMALLINT      IDENTITY (1, 1) NOT NULL,
    [SourceName]      VARCHAR (100) NOT NULL,
    [PartnerID]       INT           NOT NULL,
    [isBankFunded]    BIT           NULL,
    [FundingType]     VARCHAR (20)  NOT NULL,
    [AdditionalInfo1] VARCHAR (50)  NULL,
    [AdditionalInfo2] VARCHAR (50)  NULL,
    [SourceTypeID]    SMALLINT      NOT NULL,
    [SourceID]        VARCHAR (36)  NOT NULL,
    [CreatedDateTime] DATETIME2 (7) NOT NULL,
    [DisplayName]     VARCHAR (200) NULL
);

