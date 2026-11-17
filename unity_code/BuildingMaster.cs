using System;
using System.Collections.Generic;
using System.Linq;
using Unity.Mathematics;
using UnityEngine;
using UnityEngine.EventSystems;

public class BuildingMaster : MonoBehaviour
{
    public static BuildingMaster instance { get; private set; }

    [Header("Prefabs Of Buildings")]
    [SerializeField]
    private Transform parentOfDirt;
    [SerializeField]
    public Transform parentOfBuildigs;
    [SerializeField]
    public Building dirtPrefab;
    [SerializeField]
    public Building flagNormalPrefab;
    [SerializeField]
    public Building flagPointyPrefab;
    [SerializeField]
    public Building mineGoldPrefab;
    [SerializeField]
    public Building mineSilverPrefab;
    [SerializeField]
    public Building powerStationPrefab;
    [SerializeField]
    public Building railCurvePrefab;
    [SerializeField]
    public Building railStraitPrefab;
    [SerializeField]
    public Building watherPrefab;
    [SerializeField]
    public Building itemCrafterPrefab;
    [SerializeField]
    public Building marketplacePrefab;

    [Header("Important Instance")]
    [SerializeField]
    public Grid grid;
    [SerializeField]
    private Camera cam;
    [SerializeField]
    private LayerMask layerMask;
    [SerializeField]
    private float offsetOfBuilding;

    [Header("Settings")]
    public float maxMovementForClick;

    [Header("Dont Touch")]
    public List<Building> buildings = new List<Building>();

    
    private bool showMousposition = false;
    private Building toBuildObj;
    private Vector2 touchStartPosition;

    private void Awake()
    {
        if (instance != null && instance != this)
        {
            Debug.Log("BuildingMaster exist more then ones");
            Destroy(this);
        }
        else
        {
            instance = this;
        }
    }
    // Start is called before the first frame update
    void Start()
    {

    }

    // Update is called once per frame
    void Update()
    {
        // when show position the buidling willbe rendered with grid and building state
        if(showMousposition && Input.touchCount > 0 && !EventSystem.current.IsPointerOverGameObject(0))
        {
            if(Input.GetTouch(0).phase == TouchPhase.Began)
            {
                touchStartPosition = Input.GetTouch(0).position;
            }

            if(Input.GetTouch(0).phase == TouchPhase.Ended && (Input.GetTouch(0).position - touchStartPosition).magnitude < maxMovementForClick)
            {
                Vector3Int gridCell = grid.WorldToCell(GetMousPositionOnMap());
                toBuildObj.transform.position = new Vector3(GetMousPositionOnMap().x, GetMousPositionOnMap().y + offsetOfBuilding, GetMousPositionOnMap().z);
                if (CheckIfGridBuildabelForObj(toBuildObj, gridCell))
                {
                    toBuildObj.SetBuildState(true);
                    toBuildObj.GridState(true);
                }
                else
                {
                    toBuildObj.SetBuildState(false);
                    toBuildObj.GridState(true);
                }
                
            } 
        }
    }

    // return the rails that the train shold drive on.In direction PS -> end  
    public List<Building> GetRailsForTrain()
    {
        List<Building> rails = new List<Building>();
        Building powerStation;
        foreach(Building building in buildings)
        {
            if(building.type == "PowerStation")
            {
                powerStation = building;
                rails.Add(powerStation);
                foreach(Building b in GetBuildingsArround(powerStation))
                {
                    if (b.type == "RailStrait")
                    {
                        foreach(Building bl in GetBuildingsArround(b))
                        {
                            if (bl == powerStation)
                            {
                                rails.Add(b);
                            }
                            
                        }
                        
                    }
                }
            }
            
        }
        int preLenghOfRails = 1;
        while (preLenghOfRails != rails.Count)
        {
            preLenghOfRails = rails.Count;
            foreach (Building b in GetBuildingsArround(rails[preLenghOfRails - 1]))
            {
                if (b.type == "RailStrait" || b.type == "RailCurve")
                {
                    if (!rails.Contains(b))
                    {
                        foreach (Building bl in GetBuildingsArround(b))
                        {
                            if (bl == rails[preLenghOfRails - 1])
                            {
                                rails.Add(b);
                            }
                        }
                    }
                }
            }
        }
        return rails;

    }

    // return teh raisl with teh futur rails PS -> end
    private List<Building> GetRailsWithFutureRail(List<Building> futurRails, List<Vector3Int> futurGridCells)
    {
        List<Building> rails = new List<Building>();
        Building powerStation;
        foreach (Building building in buildings)
        {
            if (building.type == "PowerStation")
            {
                powerStation = building;
                rails.Add(powerStation);
                foreach (Building b in GetBuildingsArround(powerStation))
                {
                    if (b.type == "RailStrait")
                    {
                        foreach (Building bl in GetBuildingsArround(b))
                        {
                            if (bl == powerStation)
                            {
                                rails.Add(b);
                            }

                        }

                    }
                }
            }

        }
        int preLenghOfRails = 1;
        while (preLenghOfRails != rails.Count)
        {
            preLenghOfRails = rails.Count;
            foreach (Building b in GetBuildingsArroundWithOffset(rails[preLenghOfRails - 1]))
            {
                if (b.type == "RailStrait" || b.type == "RailCurve")
                {
                    if (!rails.Contains(b))
                    {
                        foreach (Building bl in GetBuildingsArround(b))
                        {
                            if (bl == rails[preLenghOfRails - 1])
                            {
                                rails.Add(b);
                            }
                            if (futurGridCells.Contains(bl.coordinats))
                            {
                                int index2 = futurGridCells.IndexOf(bl.coordinats);
                                Building futurRail2 = futurRails[index2];
                                if (rails.Contains(futurRail2))
                                {
                                    rails.Add(b);
                                }
                            }
                        }
                    }
                }
                if (futurGridCells.Contains(b.coordinats))
                {
                    int index = futurGridCells.IndexOf(b.coordinats);
                    Building futurRail = futurRails[index];
                    if (!rails.Contains(futurRail))
                    {
                        foreach (Building bl in GetBuildingsArroundWithOffset(futurRail))
                        {
                            if (bl == rails[preLenghOfRails - 1])
                            {
                                rails.Add(futurRail);
                            }
                            if (futurGridCells.Contains(bl.coordinats))
                            {
                                int index2 = futurGridCells.IndexOf(bl.coordinats);
                                Building futurRail2 = futurRails[index2];
                                if (rails.Contains(futurRail2))
                                {
                                    rails.Add(futurRail);
                                }
                            }
                        }
                    }
                }
            }
        }
        
        return rails;
    }

    // return the Buildings that are at the coordiants of the coordinats to check
    public List<Building> GetBuildingsArround(Building building)
    {
        List<Building> buildingsArround = new List<Building>();
        foreach(Transform co in building.coordinatsToCheck)
        {
            Vector3Int realCoordinatToCheck = grid.WorldToCell(co.position);
            foreach(Building b in buildings)
            {
                if(realCoordinatToCheck == b.coordinats)
                {
                    buildingsArround.Add(b);
                }
            }
        }
        return buildingsArround;
    }

    // return all the buildings arround. Also when they have an offset
    public List<Building> GetBuildingsArroundWithOffset(Building building)
    {
        List<Building> buildingsArround = new List<Building>();
        foreach (Transform co in building.coordinatsToCheck)
        {
            Vector3 withOutOffset = new Vector3(co.position.x, co.position.y - offsetOfBuilding, co.position.z);
            Vector3 realCoordinatToCheck = grid.WorldToCell(withOutOffset);
            foreach (Building b in buildings)
            {
                if (realCoordinatToCheck == b.coordinats)
                {
                    buildingsArround.Add(b);
                }
            }
        }
        foreach(Building b in GetBuildingsArround(building))
        {
            if (!buildingsArround.Contains(b))
            {
                buildingsArround.Add(b);
            }
        }
        return buildingsArround;
    }

    //place the building if it is buildabel in gridcell and update Data and destroy obj at this position
    public void PlaceToBuildObj()
    {
        if (toBuildObj != null && showMousposition)
        {
            Vector3Int gridCell = grid.WorldToCell(new Vector3(toBuildObj.transform.position.x, toBuildObj.transform.position.y - offsetOfBuilding, toBuildObj.transform.position.z));
            if (CheckIfGridBuildabelForObj(toBuildObj, gridCell))
            {
                showMousposition = false;
                UiMaster.instance.SetBuildMenu(false);
                UiMaster.instance.SetShopMenu(true);
                GameMaster.instance.phase = "nothing";
                DestroyBuildingOnGridForObj(toBuildObj, gridCell);
                toBuildObj.transform.position = grid.GetCellCenterWorld(gridCell);
                toBuildObj.SetUp(gridCell);
                toBuildObj.DeactivatBuildingState();
                toBuildObj.GridState(false);
                foreach(Building b in buildings)
                {
                    b.resourceBuildings.Clear();
                    b.inObeservationArea = false;
                }
                foreach (Building b in buildings)
                {
                    b.UptdateData(b.coordinats);
                }
            }
            
        }
        
    }

    // place any Obj when position is empty
    public void PlaceObj(Building building, Vector3 pos)
    {
        Vector3Int gridCell = grid.WorldToCell(pos);
        if (CheckIfGridEmpty(gridCell))
        {
            Building newBuilding = Instantiate(building, grid.GetCellCenterWorld(gridCell), Quaternion.identity, parentOfBuildigs);
            newBuilding.SetUp(gridCell);
        }
        
    }  

    // rotate the Building
    public void RotateToBuildObj()
    {
        if(toBuildObj != null)
        {
            toBuildObj.transform.Rotate(new Vector3(0, 90, 0));

            Vector3Int gridCell = grid.WorldToCell(new Vector3(toBuildObj.transform.position.x, toBuildObj.transform.position.y - offsetOfBuilding, toBuildObj.transform.position.z));
            if (CheckIfGridBuildabelForObj(toBuildObj, gridCell))
            {
                toBuildObj.SetBuildState(true);
                toBuildObj.GridState(true);
            }
            else
            {
                toBuildObj.SetBuildState(false);
                toBuildObj.GridState(true);
            }
        }
    }

    // start Building by instatiating the Buidling and set showMousposition to true
    public void StartBuildingWithObj(Building building)
    {
        GameMaster.instance.phase = "build";
        Vector3 startPosition = new Vector3(buildings[0].transform.position.x, buildings[0].transform.position.y + offsetOfBuilding, buildings[0].transform.position.z);
        Ray ray = cam.ScreenPointToRay(new Vector3(Screen.width / 2, Screen.height / 2, 0));
        RaycastHit hit;
        if (Physics.Raycast(ray, out hit, math.INFINITY, layerMask))
        {
            Vector3Int gridPosition = grid.WorldToCell(hit.point);
            startPosition = grid.GetCellCenterWorld(gridPosition);
            startPosition = new Vector3(startPosition.x, startPosition.y + offsetOfBuilding, startPosition.z);
        }
        toBuildObj = Instantiate(building, startPosition, Quaternion.identity, parentOfBuildigs);
        Vector3Int gridCell = grid.WorldToCell(new Vector3(toBuildObj.transform.position.x, toBuildObj.transform.position.y - offsetOfBuilding, toBuildObj.transform.position.z));
        if (CheckIfGridBuildabelForObj(toBuildObj, gridCell))
        {
            toBuildObj.SetBuildState(true);
            toBuildObj.GridState(true);
        }
        else
        {
            toBuildObj.SetBuildState(false);
            toBuildObj.GridState(true);
        }
        toBuildObj.UptdateData(new Vector3Int(0,0,0));
        showMousposition = true;
        UiMaster.instance.SetBuildMenu(true);
        UiMaster.instance.SetShopMenu(false);
        UiMaster.instance.SetShop(false);
    }

    // return position of mous in grid cells
    private Vector3 GetMousPositionOnMap()
    {
        Vector3 lastPosition = new Vector3(1,0,1);
        Vector3 mousePos = Input.mousePosition;
        Ray ray = cam.ScreenPointToRay(mousePos);
        RaycastHit hit;
        if(Physics.Raycast(ray, out hit, math.INFINITY, layerMask))
        {
            Vector3Int gridPosition = grid.WorldToCell(hit.point);
            lastPosition = grid.GetCellCenterWorld(gridPosition);
        }
        return lastPosition;
    }

    // retrun true when grid is empty
    private bool CheckIfGridEmpty(Vector3Int gridCell)
    {
        foreach(Building b in buildings)
        {
            if(b.coordinats == gridCell)
            {
                return false;
            }
        }
        return true;
    }

    // return true when position is buildabel for Obj: on dirt
    private bool CheckIfGridBuildabelForObj(Building building,Vector3Int gridCell)
    {
        bool gridCellbuildabel = false;
        List<bool> exBBuildabel = new List<bool>();
        foreach(Building b in buildings)
        {
            if (b.coordinats == gridCell && b.type == "Dirt" && CheckIfRailsNotBlocked(building, gridCell))
            {
                
                if (building.type == "RailStrait" || building.type == "RailCurve")
                {
                    gridCellbuildabel = true;
                }
                else if (b != GetConnectionOfRails()) 
                {
                    gridCellbuildabel = true;
                }
                foreach (Building exB in building.extraBuildings)
                {
                    //Debug.Log((exB.transform.position - building.transform.position) / 2);
                    //Debug.Log(Vector3Int.RoundToInt((exB.transform.position - building.transform.position) / 2));
                    //Debug.Log(gridCell);
                    //Debug.Log((gridCell + Vector3Int.RoundToInt((exB.transform.position - building.transform.position) / 2)));
                    foreach (Building bl in buildings)
                    {
                        Vector3Int hisGridCell = gridCell + Vector3Int.RoundToInt((exB.transform.position - building.transform.position) / 2);
                        if (bl.coordinats == hisGridCell && bl.type == "Dirt")
                        {
                            exBBuildabel.Add(true);
                        }
                    }

                }
            }
        }
        if (gridCellbuildabel == true && exBBuildabel.Count == (building.extraBuildings.Count))
        {
            return true;
        }
        else
        {
            return false;
        }
    } 

    // destroy all building for Obj
    public void DestroyBuildingOnGridForObj(Building building, Vector3Int gridCell)
    {
        List<Building> buildingsToRemove = new List<Building>();
        foreach (Building b in buildings)
        {
            if (b.coordinats == gridCell)
            {
                buildingsToRemove.Add(b); 
                foreach(Building exB in building.extraBuildings)
                {
                    foreach(Building bl in buildings)
                    {
                        Debug.Log((exB.transform.position - building.transform.position) / 2);
                        if (bl.coordinats == gridCell + Vector3Int.RoundToInt((exB.transform.position - building.transform.position) / 2))
                        {
                            buildingsToRemove.Add(bl);
                        }
                    }
                }
            }
        }
        if(buildingsToRemove != null)
        {
            foreach(Building b in buildingsToRemove)
            {
                buildings.Remove(b);
                Destroy(b.gameObject);
            }

        }

    }

    // says any mine to distribut Items
    public void DistributeItems()
    {
        foreach(Building b in buildings)
        {
            if(b.type == "MineGold" || b.type == "MineSilver")
            {
                b.GetComponent<Mine>().GiveResource();
            }
        }
    }

    // returns the dirt at the open end of the rails
    private Building GetConnectionOfRails()
    {
        Building lastRail = GetRailsForTrain().Last();
        Building connectionBuilding = null;
        foreach(Building b in GetBuildingsArround(lastRail))
        {
            if (b.type == "Dirt")
            {
                connectionBuilding = b;
            }
        }
        if(connectionBuilding != null)
        {
            return connectionBuilding;
        }
        else
        {
            return null;
        }
    }

    //return the dirt at the open end of the rails with the futur rails
    private Building GetConnectionOfFutureRails(List<Building> futurRails, List<Vector3Int> futurGridCells)
    {
        Building lastRail = GetRailsWithFutureRail(futurRails, futurGridCells).Last();
        Building connectionBuilding = null;
        foreach (Building b in GetBuildingsArroundWithOffset(lastRail))
        {
            if (b.type == "Dirt" && !futurGridCells.Contains(b.coordinats))
            {
                connectionBuilding = b;
            }
        }
        if (connectionBuilding != null)
        {
            return connectionBuilding;
        }
        else
        {
            return null;
        }
    }

    //check if raisl get blocked
    private bool CheckIfRailsNotBlocked(Building building, Vector3Int gridCell)
    {
        bool isNotBlocked = true;
        bool isInFrontOfRail = false;

        if (gridCell == GetConnectionOfRails().coordinats)
        {
            isInFrontOfRail = true;
        }
        foreach (Building exB in building.extraBuildings)
        {
            Vector3Int hisGridCell = gridCell + Vector3Int.RoundToInt((exB.transform.position - building.transform.position) / 2);
            if (hisGridCell == GetConnectionOfRails().coordinats)
            {
                isInFrontOfRail = true;
            }
        }
        if ((building.type == "RailStrait" || building.type == "RailCurve") && isInFrontOfRail)
        {
            List<Building> futurRails = new List<Building>();
            List<Vector3Int> futurGridCells = new List<Vector3Int>();

            futurRails.Add(building);
            futurRails.AddRange(building.extraBuildings);
            futurGridCells.Add(gridCell);
            foreach (Building exB in building.extraBuildings)
            {
                Vector3Int hisGridCell = gridCell + Vector3Int.RoundToInt((exB.transform.position - building.transform.position) / 2);
                futurGridCells.Add(hisGridCell);
            }

            if (GetRailsForTrain().Count == GetRailsWithFutureRail(futurRails, futurGridCells).Count)
            {
                isNotBlocked = false;
            }
            if(GetConnectionOfFutureRails(futurRails, futurGridCells) == null)
            {
                isNotBlocked = false;
            }
        }
        else
        {
            if (isInFrontOfRail)
            {
                isNotBlocked = false;
            }
            
        }

        return isNotBlocked;

        
    }

    public void BuildingClicked(Building building)
    {
        building.Clicked();
    }

}
