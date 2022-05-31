CREATE TABLE [kevinc].[Escalations] (
    [TicketNumber] VARCHAR (20)  NOT NULL,
    [Type]         VARCHAR (20)  NULL,
    [Programme]    VARCHAR (5)   NOT NULL,
    [Category]     VARCHAR (250) NOT NULL,
    [Opened Date]  DATE          NULL,
    [SLA Date]     DATE          NULL,
    [Closed Date]  DATE          NULL,
    [With Reward]  BIT           NOT NULL
);

