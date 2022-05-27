CREATE TABLE [MI].[SchemeTransCombination] (
    [ConsumerCombinationID] INT  NOT NULL,
    [OutletID]              INT  NOT NULL,
    [PartnerID]             INT  NOT NULL,
    [IsOnline]              BIT  NOT NULL,
    [StartDate]             DATE NOT NULL,
    [EndDate]               DATE NULL,
    CONSTRAINT [PK_MI_SchemeTransCombination] PRIMARY KEY CLUSTERED ([ConsumerCombinationID] ASC)
);

