using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Building : MonoBehaviour
{
    [Header("Settings")]

    public List<Transform> coordinatsToCheck;
    public List<Building> extraBuildings;
    public List<MeshRenderer> greenBuildingState;
    public List<MeshRenderer> redBuildingState;
    public MeshRenderer grid;
    public string type;
    public Sprite image;
    public bool iAmAExtraBuilding = false;

    [Header("Dont Touch")]
    public Vector3Int coordinats;
    public List<Mine> resourceBuildings = new List<Mine>();
    public bool inObeservationArea;
    public int level = 1;


    // Start is called before the first frame update
    void Start()
    {

    }

    // Update is called once per frame
    void Update()
    {

    }

    // make this bUilding in List
    // when flag dirt will be placed
    // when mine the rails will be updated for Resources
    public virtual void SetUp(Vector3Int newCoordinats)
    {
        BuildingMaster.instance.buildings.Add(this);
        foreach(Building b in extraBuildings)
        {
            Vector3Int gridCell = BuildingMaster.instance.grid.WorldToCell(new Vector3(b.transform.position.x, b.transform.position.y, b.transform.position.z));
            b.SetUp(gridCell);
            b.iAmAExtraBuilding = true;
        }
        coordinats = newCoordinats;


    }

    // Update coordinats and when MIne the rails get Updated
    public virtual void UptdateData(Vector3Int newCoordinats)
    {
        coordinats = newCoordinats;
    }

    // Set up the green and red blocks for Builing state
    public void SetBuildState(bool state)
    {
        if (state)
        {   foreach(MeshRenderer ren in greenBuildingState)
            {
                ren.enabled = true;
            }
            foreach (MeshRenderer ren in redBuildingState)
            {
                ren.enabled = false;
            }
        }
        else
        {
            foreach (MeshRenderer ren in greenBuildingState)
            {
                ren.enabled = false;
            }
            foreach (MeshRenderer ren in redBuildingState)
            {
                ren.enabled = true;
            }
        }
    }

    // make block invesabel
    public void DeactivatBuildingState()
    {
        foreach (MeshRenderer ren in greenBuildingState)
        {
            ren.enabled = false;
        }
        foreach (MeshRenderer ren in redBuildingState)
        {
            ren.enabled = false;
        }
    }

    // aktivate the grid
    public void GridState(bool state)
    {
        if (state)
        {
            grid.enabled = true;
        }
        else
        {
            grid.enabled = false;
        }

    }

    public virtual void Clicked()
    {

    }

    public virtual void NextRound()
    {

    }

}
