CREATE TABLE [Prototype].[CardholderProjections_Archive] (
    [VersionNo]             INT          NOT NULL,
    [WeekDate]              DATE         NOT NULL,
    [PublisherName]         VARCHAR (50) NOT NULL,
    [PublisherID]           INT          NULL,
    [CumulativeCardholders] INT          NULL,
    [AddedCardholders]      INT          NULL,
    PRIMARY KEY CLUSTERED ([VersionNo] ASC, [WeekDate] ASC, [PublisherName] ASC)
);

