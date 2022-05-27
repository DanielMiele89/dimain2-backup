CREATE TABLE [Relational].[Partner_CBPDates] (
    [PartnerID]        INT      NOT NULL,
    [Scheme_StartDate] DATETIME NULL,
    [Scheme_EndDate]   DATETIME NULL,
    [Coalition_Member] BIT      NULL
);


GO
CREATE CLUSTERED INDEX [ix_Partner_CBPDates_PartnerID]
    ON [Relational].[Partner_CBPDates]([PartnerID] ASC);

