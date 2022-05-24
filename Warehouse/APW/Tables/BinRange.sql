CREATE TABLE [APW].[BinRange] (
    [ID]       INT          IDENTITY (1, 1) NOT NULL,
    [BinStart] INT          NOT NULL,
    [BinEnd]   INT          NOT NULL,
    [Scheme]   VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_APW_BinRange] PRIMARY KEY CLUSTERED ([ID] ASC)
);

