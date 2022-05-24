CREATE TABLE [Relational].[Partner_AboveBaseOffers_PerDay] (
    [DayDate]        DATE NULL,
    [PartnerID]      INT  NULL,
    [AboveBaseOffer] BIT  NULL
);


GO
CREATE CLUSTERED INDEX [cx_PABO]
    ON [Relational].[Partner_AboveBaseOffers_PerDay]([DayDate] ASC, [PartnerID] ASC, [AboveBaseOffer] ASC);

