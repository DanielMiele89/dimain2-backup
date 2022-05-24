CREATE TABLE [Relational].[DirectDebit_MFDD_IncentivisedOINs] (
    [ID]        INT  IDENTITY (1, 1) NOT NULL,
    [PartnerID] INT  NOT NULL,
    [OIN]       INT  NOT NULL,
    [StartDate] DATE NOT NULL,
    [EndDate]   DATE NULL,
    CONSTRAINT [PK_irectDebit_MFDD_IncentivisedOINs] PRIMARY KEY CLUSTERED ([ID] ASC)
);

