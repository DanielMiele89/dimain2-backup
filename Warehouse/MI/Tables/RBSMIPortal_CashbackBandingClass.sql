CREATE TABLE [MI].[RBSMIPortal_CashbackBandingClass] (
    [ID]        TINYINT      NOT NULL,
    [ClassDesc] VARCHAR (50) NOT NULL,
    [MinAmt]    MONEY        NOT NULL,
    [MaxAmt]    MONEY        NOT NULL,
    CONSTRAINT [PK_MI_RBSMIPortal_CashbackBandingClass] PRIMARY KEY CLUSTERED ([ID] ASC)
);

