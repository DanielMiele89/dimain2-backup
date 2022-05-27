CREATE TABLE [RBSMIPortal].[CalendarWeekMonth_ST] (
    [CalendarDate] DATE     NOT NULL,
    [TranWeekID]   SMALLINT NOT NULL,
    [TranMonthID]  SMALLINT NOT NULL,
    CONSTRAINT [PK_RBSMIPortal_CalendarWeekMonth_ST] PRIMARY KEY CLUSTERED ([CalendarDate] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IXNCL_RBSMIPortal_CalendarWeekMonth_ST]
    ON [RBSMIPortal].[CalendarWeekMonth_ST]([TranWeekID] ASC, [TranMonthID] ASC);

