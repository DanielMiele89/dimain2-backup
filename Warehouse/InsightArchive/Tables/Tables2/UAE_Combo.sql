CREATE TABLE [InsightArchive].[UAE_Combo] (
    [ConsumerCombinationID] INT           NOT NULL,
    [BrandID]               SMALLINT      NOT NULL,
    [MID]                   VARCHAR (50)  NOT NULL,
    [Narrative]             VARCHAR (50)  NOT NULL,
    [MCCID]                 SMALLINT      NOT NULL,
    [MCC]                   VARCHAR (4)   NOT NULL,
    [MCCDesc]               VARCHAR (200) NOT NULL,
    [LocationCountry]       VARCHAR (3)   NOT NULL,
    [IsCreditOrigin]        BIT           NOT NULL,
    PRIMARY KEY CLUSTERED ([ConsumerCombinationID] ASC)
);

