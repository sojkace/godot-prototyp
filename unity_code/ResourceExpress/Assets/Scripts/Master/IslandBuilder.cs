using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class IslandBuilder : MonoBehaviour
{
    [SerializeField]
    private float minRadius;
    [SerializeField]
    private float maxRadius;
    [SerializeField]
    private float minDeegrees;
    [SerializeField]
    private float maxDeegrees;
    private Building dirtPrefab;
    private Building flagNormalPrefab;
    private Building flagPointyPrefab;
    private Building mineGoldPrefab;
    private Building mineSilverPrefab;
    private Building powerStationPrefab;
    private Building railCurvePrefab;
    private Building railStraitPrefab;
    private Building watherPrefab;
    private Building itemCrafterPrefab;
    private Building marketplacePrefab;
    [SerializeField]
    private int checkSize;
    [SerializeField]
    private Transform parentOfDirt;
    [SerializeField]
    private Transform parentOfBuildings;
    [SerializeField]
    private Grid grid;

    [SerializeField]
    private PolygonCollider2D polyCollider;
    private List<Vector2> vertices;

    public static IslandBuilder instance { get; private set; }

    private void Awake()
    {
        if (instance != null && instance != this)
        {
            Debug.Log("IslandBuilder exist more then ones");
            Destroy(this);
        }
        else
        {
            instance = this;
        }

        dirtPrefab = BuildingMaster.instance.dirtPrefab;
        flagNormalPrefab = BuildingMaster.instance.flagNormalPrefab;
        flagPointyPrefab = BuildingMaster.instance.flagPointyPrefab;
        mineGoldPrefab = BuildingMaster.instance.mineGoldPrefab;
        mineSilverPrefab = BuildingMaster.instance.mineSilverPrefab;
        powerStationPrefab = BuildingMaster.instance.powerStationPrefab;
        railCurvePrefab = BuildingMaster.instance.railCurvePrefab;
        railStraitPrefab = BuildingMaster.instance.railStraitPrefab;
        watherPrefab = BuildingMaster.instance.watherPrefab;
        itemCrafterPrefab = BuildingMaster.instance.itemCrafterPrefab;
        marketplacePrefab = BuildingMaster.instance.marketplacePrefab;
    }

    

    private Vector2 RotateVec(Vector2 vector, float degrees)
    {
        return Quaternion.Euler(0, 0, degrees) * vector;
    }

    private void PlaceDirt()
    {
        var bounds = polyCollider.bounds;
        var center = bounds.center;
        var extents = bounds.extents;
        var leftBottom = center - extents;
        var rightTop = center + extents;

        for(var x = leftBottom.x; x < rightTop.x; x += checkSize)
        {
            for (var y = leftBottom.y; y < rightTop.y; y += checkSize)
            {
                
                if(polyCollider.OverlapPoint(new Vector2(x,y)))
                {
                    Vector3Int gridPosition = grid.WorldToCell(new Vector3(x, y, 0));
                    Building nextBuilding = Instantiate(dirtPrefab, grid.GetCellCenterWorld(gridPosition), Quaternion.Euler(90,0,0), parentOfDirt).GetComponent<Building>();
                    nextBuilding.SetUp(gridPosition);
                }

            }
        }

        parentOfDirt.transform.rotation = Quaternion.Euler(-90, 0, 0);
        foreach (Building building in BuildingMaster.instance.buildings)
        {
            building.transform.SetParent(null, true);
            Vector3Int gridPosition = grid.WorldToCell(building.transform.position);
            building.transform.position = grid.GetCellCenterWorld(gridPosition);
        }
        parentOfDirt.transform.rotation = Quaternion.Euler(0, 0, 0);
        foreach (Building building in BuildingMaster.instance.buildings)
        {
            building.transform.SetParent(parentOfDirt, true);
            Vector3Int gridPosition = grid.WorldToCell(building.transform.position);
            building.UptdateData(gridPosition);
            building.transform.position = grid.GetCellCenterWorld(gridPosition);
        }

        Vector3Int gridCell = BuildingMaster.instance.buildings[0].coordinats;
        Building firstStraitRail = Instantiate(powerStationPrefab, grid.GetCellCenterWorld(gridCell), Quaternion.Euler(0,180,0), parentOfBuildings);
        BuildingMaster.instance.DestroyBuildingOnGridForObj(firstStraitRail, gridCell);
        firstStraitRail.SetUp(grid.WorldToCell(firstStraitRail.transform.position));

        gridCell = new Vector3Int(firstStraitRail.coordinats.x, 0, firstStraitRail.coordinats.z - 1);
        Building secondStraitRail = Instantiate(railStraitPrefab, grid.GetCellCenterWorld(gridCell), Quaternion.identity, parentOfBuildings);
        BuildingMaster.instance.DestroyBuildingOnGridForObj(secondStraitRail, gridCell);
        secondStraitRail.SetUp(grid.WorldToCell(secondStraitRail.transform.position));

        gridCell = new Vector3Int(secondStraitRail.coordinats.x, 0, secondStraitRail.coordinats.z - 1);
        Building firstCurveRail = Instantiate(railCurvePrefab, grid.GetCellCenterWorld(gridCell), Quaternion.Euler(0,-90,0), parentOfBuildings);
        BuildingMaster.instance.DestroyBuildingOnGridForObj(firstCurveRail, gridCell);
        firstCurveRail.SetUp(grid.WorldToCell(firstCurveRail.transform.position));

        gridCell = new Vector3Int(firstCurveRail.coordinats.x + 1, 0, firstCurveRail.coordinats.z);
        Building fourthStraitRail = Instantiate(railStraitPrefab, grid.GetCellCenterWorld(gridCell), Quaternion.Euler(0, -90, 0), parentOfBuildings);
        BuildingMaster.instance.DestroyBuildingOnGridForObj(fourthStraitRail, gridCell);
        fourthStraitRail.SetUp(grid.WorldToCell(fourthStraitRail.transform.position));

        gridCell = new Vector3Int(fourthStraitRail.coordinats.x + 1, 0, firstCurveRail.coordinats.z);
        Building fifthStraitRail = Instantiate(railStraitPrefab, grid.GetCellCenterWorld(gridCell), Quaternion.Euler(0, -90, 0), parentOfBuildings);
        BuildingMaster.instance.DestroyBuildingOnGridForObj(fifthStraitRail, gridCell);
        fifthStraitRail.SetUp(grid.WorldToCell(fifthStraitRail.transform.position));

        gridCell = new Vector3Int(fifthStraitRail.coordinats.x + 1, 0, fifthStraitRail.coordinats.z);
        Building sixthStraitRail = Instantiate(railStraitPrefab, grid.GetCellCenterWorld(gridCell), Quaternion.Euler(0, -90, 0), parentOfBuildings);
        BuildingMaster.instance.DestroyBuildingOnGridForObj(sixthStraitRail, gridCell);
        sixthStraitRail.SetUp(grid.WorldToCell(sixthStraitRail.transform.position));

        gridCell = new Vector3Int(sixthStraitRail.coordinats.x + 1, 0, sixthStraitRail.coordinats.z);
        Building firstPSRail = Instantiate(railCurvePrefab, grid.GetCellCenterWorld(gridCell), Quaternion.Euler(0, 180, 0), parentOfBuildings);
        BuildingMaster.instance.DestroyBuildingOnGridForObj(firstPSRail, gridCell);
        firstPSRail.SetUp(grid.WorldToCell(firstPSRail.transform.position));

        gridCell = new Vector3Int(secondStraitRail.coordinats.x + 1, 0, secondStraitRail.coordinats.z);
        Building firstMineGold = Instantiate(mineGoldPrefab, grid.GetCellCenterWorld(gridCell), Quaternion.Euler(0, -90, 0), parentOfBuildings);
        BuildingMaster.instance.DestroyBuildingOnGridForObj(firstMineGold, gridCell);
        firstMineGold.SetUp(grid.WorldToCell(firstMineGold.transform.position));

        gridCell = new Vector3Int(firstStraitRail.coordinats.x + 1, 0, firstStraitRail.coordinats.z);
        Building firstItemCrafter = Instantiate(itemCrafterPrefab, grid.GetCellCenterWorld(gridCell), Quaternion.Euler(0, 0, 0), parentOfBuildings);
        BuildingMaster.instance.DestroyBuildingOnGridForObj(firstItemCrafter, gridCell);
        firstItemCrafter.SetUp(grid.WorldToCell(firstItemCrafter.transform.position));

        gridCell = new Vector3Int(firstItemCrafter.coordinats.x, 0, firstItemCrafter.coordinats.z + 1);
        Building firstMarketplace = Instantiate(marketplacePrefab, grid.GetCellCenterWorld(gridCell), Quaternion.Euler(0, 0, 0), parentOfBuildings);
        BuildingMaster.instance.DestroyBuildingOnGridForObj(firstMarketplace, gridCell);
        firstMarketplace.SetUp(grid.WorldToCell(firstMarketplace.transform.position));

    }

    public void GenerateIsland()
    {
        vertices = new List<Vector2>();
        var totalRotation = 0f;
        while (true)
        {
            totalRotation += GetRandomLineRotation();
            if (totalRotation >= 360) break;
            vertices.Add(GenerateVertex(totalRotation));
        }
        polyCollider.points = vertices.ToArray();
        PlaceDirt();
    }

    private Vector3 GenerateVertex(float rotation)
    {
        var center = (Vector2) transform.position;
        var horizontaLine = new Vector2(GetRandomDistance(), 0);
        var rotatedLine = RotateVec(horizontaLine, rotation);
        return rotatedLine + center;

    }

    private float GetRandomDistance()
    {
        return Random.Range(minRadius, maxRadius);
    }

    private float GetRandomLineRotation()
    {
        return Random.Range(minDeegrees, maxDeegrees);
    }
}
