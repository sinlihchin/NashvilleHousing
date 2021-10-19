/*

Data Cleaning in SQL queries

*/
-------------------------------------------------------------

-- Overview of the data set
SELECT *
FROM PortfolioProject..Nashville

-- Reduce redundancy by removing time using CONVERT 
SELECT 
	SaleDate, 
	CONVERT(Date, SaleDate)
FROM PortfolioProject..Nashville

-- Replace SaleDate with new SaleDate without time
UPDATE Nashville
SET SaleDate = CONVERT(Date, SaleDate)

-- If above query doesn't work, add new SaleDateConverted column
ALTER TABLE Nashville
ADD SaleDateConverted Date;

-- Populate SaleDateConverted with new SaleDate
UPDATE Nashville
SET SaleDateConverted = CONVERT(Date, SaleDate)

-------------------------------------------------------------

-- Property address has NULL values
SELECT PropertyAddress
FROM PortfolioProject..Nashville
WHERE PropertyAddress IS NULL

-- ParcelID has duplicates so if there is 2 same ParcelID but 1 is without address, can use the other with address to populate
SELECT PropertyAddress
FROM PortfolioProject..Nashville
ORDER BY ParcelID

-- Do a self join
SELECT 
	a.ParcelID, 
	a.PropertyAddress, 
	b.ParcelID, 
	b.PropertyAddress,
	-- Use ISNULL to locate NULL address in a and replace with b address
	ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..Nashville AS a
JOIN PortfolioProject..Nashville AS b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
--WHERE a.PropertyAddress is null

-- Populate NULL addresses fields
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..Nashville AS a
JOIN PortfolioProject..Nashville AS b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]

-------------------------------------------------------------

--Breaking out address into individual columns (address, city, state)
SELECT PropertyAddress
FROM PortfolioProject.dbo.Nashville

SELECT
-- Get the string starting from position 1 up to comma, this retrieves the address
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)) 				AS Address,
-- Get the string starting 1 position after comma up to end of string, this retrieves the city
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) 	AS Address
FROM PortfolioProject.dbo.Nashville

-- Create new PropertySplitAddress column
ALTER TABLE Nashville
ADD PropertySplitAddress nvarchar(255);

-- Populate new PropertySplitAddress
UPDATE Nashville
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

-- Create new PropertySplitCity column
ALTER TABLE Nashville
ADD PropertySplitCity nvarchar(255);

-- Populate with city
UPDATE Nashville
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))

-------------------------------------------------------------

SELECT OwnerAddress
FROM PortfolioProject.dbo.Nashville


SELECT
	-- Alternative to SUBSTRING: breaking full address into address, city, state
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM PortfolioProject.dbo.Nashville

-- Add 3 new columns to keep the broken up address
ALTER TABLE Nashville
ADD OwnerSplitAddress nvarchar(255);

UPDATE Nashville
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE Nashville
ADD OwnerSplitCity nvarchar(255);

UPDATE Nashville
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE Nashville
ADD OwnerSplitState nvarchar(255);

UPDATE Nashville
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

SELECT *
FROM PortfolioProject.dbo.Nashville

-------------------------------------------------------------

--Change Y and N to Yes and No in "Sold as Vacant" field

-- SoldAsVacant contains Y, N ,Yes and No. Standardise fields to be Yes and No only.
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioProject.dbo.Nashville
GROUP BY SoldAsVacant
ORDER BY 2

-- Replace Y/N with Yes/No
SELECT 
	SoldAsVacant,
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END
FROM PortfolioProject.dbo.Nashville

-- Populate
UPDATE Nashville
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
			WHEN SoldAsVacant = 'N' THEN 'No'
			ELSE SoldAsVacant
			END

-------------------------------------------------------------

-- Find Duplicates

WITH RowNumCTE AS (
SELECT *,
	-- Partition by columns that contain duplicates
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
			PropertyAddress,
			SalePrice,
			SaleDate,
			LegalReference
			ORDER BY UniqueID
		) AS row_num
FROM PortfolioProject.dbo.Nashville
--ORDER BY ParcelID
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress

-------------------------------------------------------------

--Delete Unused Columns

SELECT *
FROM PortfolioProject.dbo.Nashville

ALTER TABLE PortfolioProject.dbo.Nashville
DROP COLUMN 
	OwnerAddress, 
	TaxDistrict, 
	PropertyAddress

ALTER TABLE PortfolioProject.dbo.Nashville
DROP COLUMN SaleDate
