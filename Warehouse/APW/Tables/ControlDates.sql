CREATE TABLE [APW].[ControlDates] (
    [ID]                 INT      IDENTITY (1, 1) NOT NULL,
    [StartDate]          DATE     NOT NULL,
    [EndDate]            DATE     NOT NULL,
    [PrePeriodStartDate] DATE     NOT NULL,
    [PrePeriodEndDate]   DATE     NOT NULL,
    [DateYear]           SMALLINT NOT NULL,
    CONSTRAINT [PK_APW_ControlDates] PRIMARY KEY CLUSTERED ([ID] ASC)
);

