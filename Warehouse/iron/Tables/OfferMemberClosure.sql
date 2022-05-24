CREATE TABLE [iron].[OfferMemberClosure] (
    [EndDate]     DATETIME NOT NULL,
    [IronOfferID] INT      NOT NULL,
    [CompositeID] BIGINT   NOT NULL,
    [StartDate]   DATETIME NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [IXC_OfferMemberUpdateStaging]
    ON [iron].[OfferMemberClosure]([IronOfferID] ASC, [CompositeID] ASC, [StartDate] ASC) WITH (FILLFACTOR = 80);

