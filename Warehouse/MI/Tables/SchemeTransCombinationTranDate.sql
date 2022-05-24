CREATE TABLE [MI].[SchemeTransCombinationTranDate] (
    [ID]                    INT  IDENTITY (1, 1) NOT NULL,
    [ConsumerCombinationID] INT  NOT NULL,
    [OutletID]              INT  NOT NULL,
    [PartnerID]             INT  NOT NULL,
    [IsOnline]              BIT  NOT NULL,
    [StartDate]             DATE NOT NULL,
    [EndDate]               DATE NULL,
    [TranStartDate]         DATE NOT NULL,
    [TranEndDate]           DATE NOT NULL,
    CONSTRAINT [PK_MI_SchemeTransCombinationTranDate] PRIMARY KEY CLUSTERED ([ID] ASC)
);

