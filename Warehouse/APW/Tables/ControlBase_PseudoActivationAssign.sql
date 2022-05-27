CREATE TABLE [APW].[ControlBase_PseudoActivationAssign] (
    [ID]                     INT IDENTITY (1, 1) NOT NULL,
    [CINID]                  INT NOT NULL,
    [FirstTranMonthID]       INT NOT NULL,
    [PseudoActivatedMonthID] INT NULL,
    CONSTRAINT [PK_APW_ControlBase_PseudoActivationAssign] PRIMARY KEY CLUSTERED ([ID] ASC)
);

