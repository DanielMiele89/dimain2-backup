CREATE TABLE [Prototype].[OnCall_RunType] (
    [RunTypeID]   INT          IDENTITY (1, 1) NOT NULL,
    [RunType]     VARCHAR (15) NOT NULL,
    [PeriodType]  VARCHAR (11) NOT NULL,
    [PeriodUnits] INT          NOT NULL,
    CONSTRAINT [PK_OnCallRunTypeID] PRIMARY KEY CLUSTERED ([RunTypeID] ASC)
);

