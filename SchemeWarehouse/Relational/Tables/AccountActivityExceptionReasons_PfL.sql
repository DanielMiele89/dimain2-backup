CREATE TABLE [Relational].[AccountActivityExceptionReasons_PfL] (
    [ReasonID]        TINYINT       NOT NULL,
    [ReasonDesc]      VARCHAR (256) NOT NULL,
    [AccrueDonations] BIT           NOT NULL,
    [MakeDonations]   BIT           NOT NULL,
    PRIMARY KEY CLUSTERED ([ReasonID] ASC),
    UNIQUE NONCLUSTERED ([ReasonID] ASC)
);

