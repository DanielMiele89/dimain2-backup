
CREATE FUNCTION [Prototype].[NEtoLL] (@East INT, @North INT, @LatOrLng VARCHAR(3)) RETURNS FLOAT AS
BEGIN

--Author: Sandy Motteram
--Date:   06 September 2012

--UDF adapted from javascript at http://www.bdcc.co.uk/LatLngToOSGB.js
--found on page http://mapki.com/wiki/Tools:Snippets

--Instructions:
--Latitude and Longitude are calculated based on BOTH the easting and northing values from the OSGB36
--This UDF takes both easting and northing values in OSGB36 projection and you must specify if a latitude or longitude co-ordinate should be returned.
--IT first converts E/N values to lat and long in OSGB36 projection, then converts those values to lat/lng in WGS84 projection

--Sample values below
--DECLARE @East INT, @North INT, @LatOrLng VARCHAR(3)
--SELECT @East = 529000, @North = 183650 --that combo should be the corner of Camden High St and Delancey St


    DECLARE @Pi              FLOAT
          , @K0              FLOAT
          , @OriginLat       FLOAT
          , @OriginLong      FLOAT
          , @OriginX         FLOAT
          , @OriginY         FLOAT
          , @a               FLOAT
          , @b               FLOAT
          , @e2              FLOAT
          , @ex              FLOAT
          , @n1              FLOAT
          , @n2              FLOAT
          , @n3              FLOAT
          , @OriginNorthings FLOAT
          , @lat             FLOAT
          , @lon             FLOAT
          , @Northing        FLOAT
          , @Easting         FLOAT

    SELECT  @Pi = 3.14159265358979323846
          , @K0 = 0.9996012717 -- grid scale factor on central meridean
          , @OriginLat  = 49.0
          , @OriginLong = -2.0
          , @OriginX =  400000 -- 400 kM
          , @OriginY = -100000 -- 100 kM
          , @a = 6377563.396   -- Airy Spheroid
          , @b = 6356256.910
    /*    , @e2
          , @ex
          , @n1
          , @n2
          , @n3
          , @OriginNorthings*/

    -- compute interim values
    SELECT  @a = @a * @K0
          , @b = @b * @K0

    SET     @n1 = (@a - @b) / (@a + @b)
    SET     @n2 = @n1 * @n1
    SET     @n3 = @n2 * @n1

    SET     @lat = @OriginLat * @Pi / 180.0 -- to radians

    SELECT  @e2 = (@a * @a - @b * @b) / (@a * @a) -- first eccentricity
          , @ex = (@a * @a - @b * @b) / (@b * @b) -- second eccentricity

    SET     @OriginNorthings = @b * @lat + @b * (@n1 * (1.0 + 5.0 * @n1 * (1.0 + @n1) / 4.0) * @lat
          - 3.0 * @n1 * (1.0 + @n1 * (1.0 + 7.0 * @n1 / 8.0)) * SIN(@lat) * COS(@lat)
          + (15.0 * @n1 * (@n1 + @n2) / 8.0) * SIN(2.0 * @lat) * COS(2.0 * @lat)
          - (35.0 * @n3 / 24.0) * SIN(3.0 * @lat) * COS(3.0 * @lat))

    SELECT  @northing = @north - @OriginY
         ,  @easting  = @east  - @OriginX

    DECLARE @nu       FLOAT
          , @phid     FLOAT
          , @phid2    FLOAT
          , @t2       FLOAT
          , @t        FLOAT
          , @q2       FLOAT
          , @c        FLOAT
          , @s        FLOAT
          , @nphid    FLOAT
          , @dnphid   FLOAT
          , @nu2      FLOAT
          , @nudivrho FLOAT
          , @invnurho FLOAT
          , @rho      FLOAT
          , @eta2     FLOAT

    /* Evaluate M term: latitude of the northing on the centre meridian */

    SET     @northing = @northing + @OriginNorthings

    SET     @phid  = @northing / (@b*(1.0 + @n1 + 5.0 * (@n2 + @n3) / 4.0)) - 1.0
    SET     @phid2 = @phid + 1.0

    WHILE (ABS(@phid2 - @phid) > 0.000001)
    BEGIN
        SET @phid = @phid2;
        SET @nphid = @b * @phid + @b * (@n1 * (1.0 + 5.0 * @n1 * (1.0 + @n1) / 4.0) * @phid
                   - 3.0 * @n1 * (1.0 + @n1 * (1.0 + 7.0 * @n1 / 8.0)) * SIN(@phid) * COS(@phid)
                   + (15.0 * @n1 * (@n1 + @n2) / 8.0) * SIN(2.0 * @phid) * COS(2.0 * @phid)
                   - (35.0 * @n3 / 24.0) * SIN(3.0 * @phid) * COS(3.0 * @phid))

        SET @dnphid = @b * ((1.0 + @n1 + 5.0 * (@n2 + @n3) / 4.0) - 3.0 * (@n1 + @n2 + 7.0 * @n3 / 8.0) * COS(2.0 * @phid)
                    + (15.0 * (@n2 + @n3) / 4.0) * COS(4 * @phid) - (35.0 * @n3 / 8.0) * COS(6.0 * @phid))

        SET @phid2 = @phid - (@nphid - @northing) / @dnphid
    END

    SELECT @c = COS(@phid)
         , @s = SIN(@phid)
         , @t = TAN(@phid)
    SELECT @t2 = @t * @t
         , @q2 = @easting * @easting

    SET    @nu2 = (@a * @a) / (1.0 - @e2 * @s * @s)
    SET    @nu = SQRT(@nu2)

    SET    @nudivrho = @a * @a * @c * @c / (@b * @b) - @c * @c + 1.0
    SET    @eta2 = @nudivrho - 1
    SET    @rho = @nu / @nudivrho;

    SET    @invnurho = ((1.0 - @e2 * @s * @s) * (1.0 - @e2 * @s * @s)) / (@a * @a * (1.0 - @e2))

    SET    @lat = @phid - @t * @q2 * @invnurho / 2.0 + (@q2 * @q2 * (@t / (24 * @rho * @nu2 * @nu) * (5 + (3 * @t2) + @eta2 - (9 * @t2 * @eta2))))
    SET    @lon = (@easting / (@c * @nu))
                - (@easting * @q2 * ((@nudivrho + 2.0 * @t2) / (6.0 * @nu2)) / (@c * @nu))
                + (@q2 * @q2 * @easting * (5 + (28 * @t2) + (24 * @t2 * @t2)) / (120 * @nu2 * @nu2 * @nu * @c))


    SELECT @lat = @lat * 180.0 / @Pi
         , @lon = @lon * 180.0 / @Pi + @OriginLong


--Now convert the lat and long from OSGB36 to WGS84

    DECLARE @OGlat  FLOAT
          , @OGlon  FLOAT
          , @height FLOAT

    SELECT  @OGlat  = @lat
          , @OGlon  = @lon
          , @height = 24 --London's mean height above sea level is 24 metres. Adjust for other locations.

    DECLARE @deg2rad  FLOAT
          , @rad2deg  FLOAT
          , @radOGlat FLOAT
          , @radOGlon FLOAT

    SELECT  @deg2rad = @Pi / 180
          , @rad2deg = 180 / @Pi

    --first off convert to radians
    SELECT  @radOGlat = @OGlat * @deg2rad
          , @radOGlon = @OGlon * @deg2rad
    --these are the values for WGS84(GRS80) to OSGB36(Airy) 

    DECLARE @a2       FLOAT
          , @h        FLOAT
          , @xp       FLOAT
          , @yp       FLOAT
          , @zp       FLOAT
          , @xr       FLOAT
          , @yr       FLOAT
          , @zr       FLOAT
          , @sf       FLOAT
          , @e        FLOAT
          , @v        FLOAT
          , @x        FLOAT
          , @y        FLOAT
          , @z        FLOAT
          , @xrot     FLOAT
          , @yrot     FLOAT
          , @zrot     FLOAT
          , @hx       FLOAT
          , @hy       FLOAT
          , @hz       FLOAT
          , @newLon   FLOAT
          , @newLat   FLOAT
          , @p        FLOAT
          , @errvalue FLOAT
          , @lat0     FLOAT

    SELECT  @a2 = 6378137             -- WGS84_AXIS
          , @e2 = 0.00669438037928458 -- WGS84_ECCENTRIC
          , @h  = @height             -- height above datum (from $GPGGA sentence)
          , @a  = 6377563.396         -- OSGB_AXIS
          , @e  = 0.0066705397616     -- OSGB_ECCENTRIC
          , @xp = 446.448
          , @yp = -125.157
          , @zp = 542.06
          , @xr = 0.1502
          , @yr = 0.247
          , @zr = 0.8421
          , @s  = -20.4894

    -- convert to cartesian; lat, lon are in radians
    SET @sf = @s * 0.000001
    SET @v = @a / (sqrt(1 - (@e * (SIN(@radOGlat) * SIN(@radOGlat)))))
    SET @x = (@v + @h) * COS(@radOGlat) * COS(@radOGlon)
    SET @y = (@v + @h) * COS(@radOGlat) * SIN(@radOGlon)
    SET @z = ((1 - @e) * @v + @h) * SIN(@radOGlat)

    -- transform cartesian
    SET @xrot = (@xr / 3600) * @deg2rad
    SET @yrot = (@yr / 3600) * @deg2rad
    SET @zrot = (@zr / 3600) * @deg2rad
    SET @hx = @x + (@x * @sf) - (@y * @zrot) + (@z * @yrot) + @xp
    SET @hy = (@x * @zrot) + @y + (@y * @sf) - (@z * @xrot) + @yp
    SET @hz = (-1 * @x * @yrot) + (@y * @xrot) + @z + (@z * @sf) + @zp

    -- Convert back to lat, lon
    SET @newLon = ATAN(@hy / @hx)
    SET @p = SQRT((@hx * @hx) + (@hy * @hy))
    SET @newLat = ATAN(@hz / (@p * (1 - @e2)))
    SET @v = @a2 / (SQRT(1 - @e2 * (SIN(@newLat) * SIN(@newLat))))
    SET @errvalue = 1.0;
    SET @lat0 = 0
    WHILE (@errvalue > 0.001)
    BEGIN
        SET @lat0 = ATAN((@hz + @e2 * @v * SIN(@newLat)) / @p)
        SET @errvalue = ABS(@lat0 - @newLat)
        SET @newLat = @lat0
    END

    --convert back to degrees
    SET @newLat = @newLat * @rad2deg
    SET @newLon = @newLon * @rad2deg

    DECLARE @ReturnMe FLOAT
    SET @ReturnMe = 0

    IF @LatOrLng = 'Lat'
        SET @ReturnMe = @newLat
    IF @LatOrLng = 'Lng'
        SET @ReturnMe = @newLon

    RETURN @ReturnMe
END
