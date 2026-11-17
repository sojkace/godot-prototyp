using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TrainMaster : MonoBehaviour
{
    public static TrainMaster instance { get; private set; }

    [Header("Don't touch")]
    [SerializeField]
    public bool isTrainRunning;
    private Grid grid;

    private void Awake()
    {
        if (instance != null && instance != this)
        {
            Debug.Log("TrainMaster exist more then ones");
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
        grid = BuildingMaster.instance.grid;
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    // starts the train
    public void StartTrain(List<Train> newTrains)
    {
        GameMaster.instance.phase = "train";
        isTrainRunning = true;
        StartCoroutine(CreatTrains(newTrains));
    }

    // should be called when train entered PS; plays animation
    public void TrainEnteredPS(Train train)
    {
        train.GetComponent<MeshRenderer>().enabled = false;
        if (train.capacity == train.numberOfItems)
        {
            Debug.Log("full");
            foreach (Building b in BuildingMaster.instance.buildings)
            {
                if (b.type == "PowerStation")
                {
                    StartCoroutine(b.GetComponent<PowerStation>().StartCoinAnimation());
                }
            }
        }
        else
        {
            Debug.Log("- heart");
            foreach (Building b in BuildingMaster.instance.buildings)
            {
                if (b.type == "PowerStation")
                {
                    StartCoroutine(b.GetComponent<PowerStation>().StartHeartAnimation());
                }
            }
        }
    }

    // creat trains and moves them till every train is in PS
    private IEnumerator CreatTrains(List<Train> newTrains)
    {
        List<Building> rails = BuildingMaster.instance.GetRailsForTrain();
        foreach(Building r in rails)
        {
            Debug.Log(r.GetInstanceID());
        }
        List<Train> trains = new List<Train>();
        foreach (Train newTrain in newTrains)
        {
            trains.Add(Instantiate(newTrain, rails[rails.Count - 1].transform.position, Quaternion.identity));
            trains[trains.Count - 1].currentRailPosition = rails.Count - 1;
            yield return MoveTrains(trains, rails);
        }

        for (int i = trains[trains.Count - 1].currentRailPosition; i >= 0; i--)
        {
            yield return MoveTrains(trains, rails);
        }
        GameMaster.instance.phase = "nothing";
        isTrainRunning = false;
        GameMaster.instance.NextRound();
    }


    // move all trains one position to PS and says Buildingmaster to destribut Items
    private IEnumerator MoveTrains(List<Train> trains, List<Building> rails)
    {
        foreach (Building b in BuildingMaster.instance.buildings)
        {
            if (b.type == "MineGold" || b.type == "MineSilver")
            {
                b.GetComponent<Mine>().trainsInMyResource.Clear();
            }
                
        }

        int i = 0;
        List<Train> trainsNotFinished = new List<Train>();
        foreach (Train t in trains)
        {
            if (t.currentRailPosition > 0)
            {
                trainsNotFinished.Add(t);
            }
        }
        foreach (Train t in trainsNotFinished)
        {
            if (i != trainsNotFinished.Count - 1)
            {
                t.currentRailPosition--;
                StartCoroutine(t.MoveToPosition(rails[t.currentRailPosition].transform.position, grid));

            }
            else
            {
                t.currentRailPosition--;
                yield return t.MoveToPosition(rails[t.currentRailPosition].transform.position, grid);

            }
            i++;
        }
        BuildingMaster.instance.DistributeItems();


    }
}
