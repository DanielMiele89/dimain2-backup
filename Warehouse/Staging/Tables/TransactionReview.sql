CREATE TABLE [Staging].[TransactionReview] (
    [BrandID]          SMALLINT      NOT NULL,
    [BrandName]        VARCHAR (50)  NOT NULL,
    [MID]              VARCHAR (50)  NOT NULL,
    [Narrative]        VARCHAR (50)  NOT NULL,
    [MCCDesc]          VARCHAR (200) NOT NULL,
    [MCCCategory]      VARCHAR (50)  NOT NULL,
    [IncenitivisedMID] INT           NOT NULL,
    [TranDate]         DATE          NOT NULL,
    [Amount]           MONEY         NOT NULL,
    [IsOnline]         BIT           NOT NULL,
    [CINID]            INT           NOT NULL
);

