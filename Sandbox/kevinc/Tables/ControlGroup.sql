CREATE TABLE [kevinc].[ControlGroup] (
    [ControlGroupID]     INT         NOT NULL,
    [PartnerID]          INT         NULL,
    [Segment]            VARCHAR (1) NULL,
    [ControlGroupTypeID] INT         NULL,
    [StartDate]          DATE        NULL,
    [EndDate]            DATE        NULL,
    [Cardholders]        INT         NULL,
    PRIMARY KEY CLUSTERED ([ControlGroupID] ASC)
);

