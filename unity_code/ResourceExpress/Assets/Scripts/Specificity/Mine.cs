using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Mine : Building
{
    [Header("Animator for Mine")]
    [SerializeField]
    private Animator gold;

    [Header("Dont Touch for Mine")]
    public List<Train> trainsInMyResource = new List<Train>();

    private void Awake()
    {
        
    }
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public override void SetUp(Vector3Int newCoordinats)
    {
        base.SetUp(newCoordinats);
        if (type == "MineGold" || type == "MineSilver")
        {
            foreach (Transform co in coordinatsToCheck)
            {
                foreach (Building b in BuildingMaster.instance.buildings)
                {
                    if (b.transform.position == co.position)
                    {
                        b.resourceBuildings.Add(this);
                    }
                }
            }
        }
    }

    public override void UptdateData(Vector3Int newCoordinats)
    {
        base.UptdateData(newCoordinats);
        if (type == "MineGold" || type == "MineSilver")
        {
            foreach (Transform co in coordinatsToCheck)
            {
                foreach (Building b in BuildingMaster.instance.buildings)
                {
                    if (b.transform.position == co.position)
                    {

                        b.resourceBuildings.Add(this);
                    }
                }
            }
        }
    }

    public void AddTrain(Train train)
    {
        trainsInMyResource.Add(train);
    }

    public void ClearTrain()
    {
        trainsInMyResource.Clear();
    }


    // For Mine when trians in list they wll be filled
    // when more the one it is Random
    // full trian will not get filled
    public void GiveResource()
    {
        if (trainsInMyResource.Count > 0)
        {
            List<Train> trainWithPlace = new List<Train>();
            foreach (Train t in trainsInMyResource)
            {
                if (t.numberOfItems < t.capacity)
                {
                    trainWithPlace.Add(t);
                }
            }
            if (trainWithPlace.Count > 0 && !inObeservationArea)
            {
                int randomTrainNumber = Random.Range(0, trainWithPlace.Count);
                gold.Play("mine");
                Debug.Log("giv Resource");
                trainWithPlace[randomTrainNumber].CollectItem();
            }
            else if (trainWithPlace.Count > 0 && inObeservationArea)
            {
                int lowestplacesInTrain = trainWithPlace[0].capacity - trainWithPlace[0].numberOfItems;
                foreach (Train t in trainWithPlace)
                {
                    if (lowestplacesInTrain > t.capacity - t.numberOfItems)
                    {
                        lowestplacesInTrain = t.capacity - t.numberOfItems;
                    }
                }
                foreach (Train t in trainWithPlace)
                {
                    if (t.capacity - t.numberOfItems == lowestplacesInTrain)
                    {
                        gold.Play("mine");
                        Debug.Log("giv Resource not random");
                        t.CollectItem();
                        break;
                    }
                }
            }

        }

    }
}
