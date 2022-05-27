CREATE TABLE [Inbound].[Publisher] (
    [PublisherID]           INT            NOT NULL,
    [PublisherName]         NVARCHAR (100) NOT NULL,
    [PublisherNickname]     NVARCHAR (50)  NULL,
    [PublisherAbbreviation] NVARCHAR (12)  NOT NULL,
    [PublisherType]         VARCHAR (25)   NULL,
    [LiveStatus]            INT            NULL
);

