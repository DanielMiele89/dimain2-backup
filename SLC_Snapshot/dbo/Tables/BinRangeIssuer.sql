CREATE TABLE [dbo].[BinRangeIssuer] (
    [ID]          NVARCHAR (6)   NOT NULL,
    [BinRange]    AS             ([id]),
    [Scheme]      NVARCHAR (20)  NOT NULL,
    [Issuer]      NVARCHAR (100) NOT NULL,
    [CardType]    NVARCHAR (50)  NOT NULL,
    [CardSubType] NVARCHAR (50)  NOT NULL,
    [Country]     NVARCHAR (50)  NOT NULL,
    [Telephone]   NVARCHAR (20)  NOT NULL,
    CONSTRAINT [PK_BinRangeIssuer] PRIMARY KEY CLUSTERED ([ID] ASC)
);

