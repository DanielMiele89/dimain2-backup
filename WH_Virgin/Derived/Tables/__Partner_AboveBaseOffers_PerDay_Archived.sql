CREATE TABLE [Derived].[__Partner_AboveBaseOffers_PerDay_Archived] (
    [DayDate]        DATE NULL,
    [PartnerID]      INT  NULL,
    [AboveBaseOffer] BIT  NULL
);


GO
CREATE CLUSTERED INDEX [cx_PABO]
    ON [Derived].[__Partner_AboveBaseOffers_PerDay_Archived]([DayDate] ASC, [PartnerID] ASC, [AboveBaseOffer] ASC);

