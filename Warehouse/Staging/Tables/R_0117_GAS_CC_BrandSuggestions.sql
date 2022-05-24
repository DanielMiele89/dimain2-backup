CREATE TABLE [Staging].[R_0117_GAS_CC_BrandSuggestions] (
    [GAS_PartnerID]         INT           NOT NULL,
    [GAS_PartnerName]       VARCHAR (100) NULL,
    [GAS_OutletID]          INT           NOT NULL,
    [GAS_MID]               NVARCHAR (50) NOT NULL,
    [CC_MID]                VARCHAR (50)  NOT NULL,
    [ConsumerCombinationID] INT           NOT NULL,
    [CC_Narrative]          VARCHAR (50)  NOT NULL,
    [MCCDescription]        VARCHAR (200) NOT NULL
);

