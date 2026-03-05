using System;
using System.Collections.Generic;
using System.Net;
using System.Net.Sockets;
using System.Text;
using UnityEngine;

public class GameAudioClient : MonoBehaviour
{
    [Header("Game Audio Engine")]
    public string host = "127.0.0.1";
    public int port = 9000;

    private UdpClient udp;
    private IPEndPoint endPoint;
    private int sceneId = 1;
    private int eventCounter = 0;

    private void Awake()
    {
        udp = new UdpClient();
        endPoint = new IPEndPoint(IPAddress.Parse(host), port);
        CreateScene("unity_scene", 1234);
    }

    private void OnDestroy()
    {
        udp?.Close();
    }

    public string SpawnHit(Vector3 pos, float gain = 0.7f, int seed = -1)
    {
        eventCounter++;
        string eventId = $"unity_evt_{eventCounter}";
        if (seed < 0) seed = UnityEngine.Random.Range(0, int.MaxValue);

        SendOsc("/event/spawn", new object[]
        {
            sceneId,
            "proc_hit",
            eventId,
            Mathf.Clamp(pos.x, -1f, 1f),
            Mathf.Clamp(pos.y, -1f, 1f),
            Mathf.Clamp(pos.z, -1f, 1f),
            Mathf.Clamp01(gain),
            seed
        });

        return eventId;
    }

    public void StopEvent(string eventId, int releaseMs = 80)
    {
        SendOsc("/event/stop", new object[] { eventId, releaseMs });
    }

    public void SetEventParam(string eventId, string key, float value, int rampMs = 0)
    {
        SendOsc("/event/param", new object[] { eventId, key, value, rampMs });
    }

    public void SetBusDb(string busName, float gainDb, int rampMs = 50)
    {
        SendOsc("/mix/bus", new object[] { busName, gainDb, rampMs });
    }

    public void CreateScene(string name, int seed)
    {
        sceneId = 1;
        SendOsc("/scene/create", new object[] { name, seed });
    }

    private void SendOsc(string address, object[] args)
    {
        byte[] packet = BuildOscPacket(address, args);
        udp.Send(packet, packet.Length, endPoint);
    }

    private static byte[] BuildOscPacket(string address, object[] args)
    {
        List<byte> data = new List<byte>(256);
        data.AddRange(OscString(address));

        StringBuilder tags = new StringBuilder(",");
        foreach (object arg in args)
            tags.Append(TypeTag(arg));

        data.AddRange(OscString(tags.ToString()));

        foreach (object arg in args)
            data.AddRange(OscArg(arg));

        return data.ToArray();
    }

    private static char TypeTag(object arg)
    {
        if (arg is int) return 'i';
        if (arg is float) return 'f';
        if (arg is string) return 's';
        return 's';
    }

    private static byte[] OscArg(object arg)
    {
        if (arg is int i) return OscInt32(i);
        if (arg is float f) return OscFloat32(f);
        return OscString(arg.ToString() ?? string.Empty);
    }

    private static byte[] OscString(string value)
    {
        byte[] utf8 = Encoding.UTF8.GetBytes(value);
        int lenWithNull = utf8.Length + 1;
        int paddedLen = (lenWithNull + 3) & ~3;

        byte[] outBytes = new byte[paddedLen];
        Buffer.BlockCopy(utf8, 0, outBytes, 0, utf8.Length);
        return outBytes;
    }

    private static byte[] OscInt32(int value)
    {
        byte[] b = BitConverter.GetBytes(value);
        if (BitConverter.IsLittleEndian) Array.Reverse(b);
        return b;
    }

    private static byte[] OscFloat32(float value)
    {
        byte[] b = BitConverter.GetBytes(value);
        if (BitConverter.IsLittleEndian) Array.Reverse(b);
        return b;
    }
}
