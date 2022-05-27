CREATE TABLE [Prototype].[ROCP2_SegFore_RunDates] (
    [BuildEnd]      DATE NULL,
    [BuildStart]    DATE NULL,
    [CA_Date]       DATE NULL,
    [BetweenDays]   INT  NULL,
    [FixedStart]    DATE NULL,
    [FixedEnd]      DATE NULL,
    [LastAvailable] DATE NULL
);


GO
CREATE CLUSTERED INDEX [IDX_BE]
    ON [Prototype].[ROCP2_SegFore_RunDates]([BuildEnd] ASC, [BuildStart] ASC);

