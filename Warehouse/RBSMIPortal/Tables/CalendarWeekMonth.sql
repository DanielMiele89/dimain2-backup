CREATE TABLE [RBSMIPortal].[CalendarWeekMonth] (
    [CalendarDate]  DATE         NOT NULL,
    [TranWeekID]    SMALLINT     NOT NULL,
    [TranMonthID]   SMALLINT     NOT NULL,
    [TranWeekDesc]  VARCHAR (50) NOT NULL,
    [TranMonthDesc] VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_RBSMIPortal_CalendarWeekMonth] PRIMARY KEY CLUSTERED ([CalendarDate] ASC)
);

