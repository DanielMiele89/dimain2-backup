CREATE TABLE [Relational].[BookingCal_OfferApprovalDates] (
    [ID]                   INT          IDENTITY (1, 1) NOT NULL,
    [CalendarYear]         INT          NOT NULL,
    [ClientServicesRef]    VARCHAR (40) NOT NULL,
    [DateForecastExpected] DATE         NULL,
    [DateBriefSubmitted]   DATE         NULL,
    [ApprovedByRetailer]   BIT          NULL,
    [ApprovedByRBSG]       BIT          NULL,
    [Status_StartDate]     DATE         NULL,
    [Status_EndDate]       DATE         NULL
);

