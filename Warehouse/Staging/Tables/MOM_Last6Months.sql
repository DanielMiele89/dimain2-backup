CREATE TABLE [Staging].[MOM_Last6Months] (
    [ID]                    INT           IDENTITY (1, 1) NOT NULL,
    [BrandID]               SMALLINT      NOT NULL,
    [BrandName]             VARCHAR (50)  NOT NULL,
    [ConsumerCombinationID] INT           NOT NULL,
    [MID]                   VARCHAR (50)  NOT NULL,
    [Narrative]             VARCHAR (50)  NOT NULL,
    [LastTranDate]          DATE          NOT NULL,
    [Amount]                MONEY         NOT NULL,
    [LocationAddress]       VARCHAR (50)  NULL,
    [OriginatorID]          VARCHAR (11)  NOT NULL,
    [MCCID]                 SMALLINT      NOT NULL,
    [MCCDesc]               VARCHAR (200) NULL,
    [AcquirerID]            INT           NULL,
    [AcquirerName]          VARCHAR (50)  NULL,
    [SplitAcquirer]         INT           NOT NULL
);

