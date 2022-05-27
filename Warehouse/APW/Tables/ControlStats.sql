CREATE TABLE [APW].[ControlStats] (
    [ID]          INT        IDENTITY (1, 1) NOT NULL,
    [MonthDate]   DATE       NOT NULL,
    [RetailerID]  INT        NOT NULL,
    [RR]          FLOAT (53) NOT NULL,
    [SPS]         FLOAT (53) NOT NULL,
    [ATV]         MONEY      NOT NULL,
    [ATF]         FLOAT (53) NOT NULL,
    [ChannelType] BIT        NULL,
    CONSTRAINT [PK_APW_ControlStats] PRIMARY KEY CLUSTERED ([ID] ASC)
);

