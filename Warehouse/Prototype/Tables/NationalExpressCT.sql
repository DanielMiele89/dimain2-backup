CREATE TABLE [Prototype].[NationalExpressCT] (
    [MerchantID]   NVARCHAR (50) NULL,
    [Incentivised] INT           NULL,
    [Branded]      INT           NULL,
    [Provided]     INT           NULL,
    [Narrative]    VARCHAR (50)  NULL,
    [CINID]        INT           NOT NULL,
    [TranDate]     DATE          NOT NULL,
    [Amount]       MONEY         NOT NULL
);

