CREATE TABLE [APW].[ControlPrePeriodSpend] (
    [TypeID]   TINYINT IDENTITY (1, 1) NOT NULL,
    [MinSpend] MONEY   NOT NULL,
    [MaxSpend] MONEY   NOT NULL,
    CONSTRAINT [PK_APW_ControlPrePeriodSpend] PRIMARY KEY CLUSTERED ([TypeID] ASC)
);

