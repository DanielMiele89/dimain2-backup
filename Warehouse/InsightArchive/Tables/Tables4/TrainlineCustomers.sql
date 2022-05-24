CREATE TABLE [InsightArchive].[TrainlineCustomers] (
    [id]          INT    IDENTITY (1, 1) NOT NULL,
    [IronOfferID] BIGINT NOT NULL,
    [CompositeID] BIGINT NOT NULL,
    [FanID]       INT    NULL,
    PRIMARY KEY CLUSTERED ([id] ASC)
);


GO
DENY SELECT
    ON OBJECT::[InsightArchive].[TrainlineCustomers] TO [New_PIIRemoved]
    AS [dbo];

