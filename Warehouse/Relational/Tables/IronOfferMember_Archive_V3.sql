CREATE TABLE [Relational].[IronOfferMember_Archive_V3] (
    [IronOfferID] INT      NULL,
    [CompositeID] BIGINT   NULL,
    [starttime]   DATETIME NULL,
    [endtime]     DATETIME NULL
)
WITH (DATA_COMPRESSION = PAGE);

