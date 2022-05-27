CREATE TABLE [Prototype].[Hack_FanIDs] (
    [FanID]             INT          NOT NULL,
    [CompositeID]       BIGINT       NULL,
    [SourceUID]         VARCHAR (20) NULL,
    [Gender]            CHAR (1)     NULL,
    [DOB]               DATE         NULL,
    [PostCode]          VARCHAR (10) NULL,
    [MarketableByEmail] BIT          NULL,
    PRIMARY KEY CLUSTERED ([FanID] ASC)
);

