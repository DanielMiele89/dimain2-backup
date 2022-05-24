CREATE TABLE [Prototype].[OnCall_Schedule] (
    [ScheduleID]   INT              IDENTITY (1, 1) NOT NULL,
    [PID]          UNIQUEIDENTIFIER NOT NULL,
    [DayID]        INT              NULL,
    [FirstRunDate] DATE             NULL,
    [PeriodType]   VARCHAR (11)     NOT NULL,
    [PeriodUnits]  INT              NOT NULL,
    CONSTRAINT [PK_OnCallScheduleID] PRIMARY KEY CLUSTERED ([ScheduleID] ASC)
);

