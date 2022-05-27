CREATE TABLE [Prototype].[CardholderProjections] (
    [WeekDate]              DATE         NOT NULL,
    [PublisherName]         VARCHAR (50) NOT NULL,
    [PublisherID]           INT          NULL,
    [CumulativeCardholders] INT          NULL,
    [AddedCardholders]      INT          NULL,
    [AddedDate]             DATE         NOT NULL,
    [ArchivedDate]          DATE         NULL,
    PRIMARY KEY CLUSTERED ([WeekDate] ASC, [PublisherName] ASC, [AddedDate] ASC)
);

