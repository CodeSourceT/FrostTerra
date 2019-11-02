package com.bedic.game.lite;

import android.app.Activity;
import android.app.Service;
import android.content.Context;
import android.content.res.AssetManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.PorterDuff;
import android.graphics.Rect;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.media.AudioAttributes;
import android.media.SoundPool;
import android.util.ArrayMap;
import android.view.MotionEvent;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;

import java.io.IOException;
import java.io.InputStream;

public class FrostTerraEngine {
    private FrostTerraRender m_render = null;
    private  FrostTerraSound m_sound = null;
    private FrostTerraEvent m_event=null;
    private Context m_context = null;
    private Activity m_activity = null;
    private boolean m_renderb = false, m_soundb = false;

    public FrostTerraEngine(Activity activity, Context context, boolean render, boolean sound)
    {
        m_context = context;
        m_activity = activity;
        m_renderb=render;
        m_soundb=sound;
    }

    public void init(FrostTerraRenderClass rc, FrostTerraSoundSettings ss)
    {
        if(m_renderb) {
            m_render = new FrostTerraRender(m_context, rc);
        }

        if(m_soundb) {
            m_sound = new FrostTerraSound(m_context, ss);
        }
    }

    public void setFullScreen()
    {
        hideSystemUI();
    }

    public void attachEventListener(FrostTerraEventListener f)
    {
        m_event = new FrostTerraEvent(f);
        m_render.setOnTouchListener(m_event);
    }

    public void activeRender()
    {
        if(m_render != null) {
            m_activity.setContentView(m_render);
        }
    }

    public FrostTerraSound getPlayerSound()
    {
        if(m_sound != null)
        {
            return m_sound;
        }

        return null;
    }

    public void stop()
    {
        if(m_soundb)
        {
            m_sound.releaseClass();
        }
    }

    private void hideSystemUI() {
        // Enables regular immersive mode.
        // For "lean back" mode, remove SYSTEM_UI_FLAG_IMMERSIVE.
        // Or for "sticky immersive," replace it with SYSTEM_UI_FLAG_IMMERSIVE_STICKY
        View decorView = m_activity.getWindow().getDecorView();
        decorView.setSystemUiVisibility(
                View.SYSTEM_UI_FLAG_IMMERSIVE
                        // Set the content to appear under the system bars so that the
                        // content doesn't resize when the system bars hide and show.
                        | View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                        | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                        | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                        // Hide the nav bar and status bar
                        | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                        | View.SYSTEM_UI_FLAG_FULLSCREEN);
    }
}

interface FrostTerraRenderClass{
    public void onDraw(Canvas canvas, Paint paint);
    public void onCanvasChange(FrostTerraRect size_canvas);
    public void onCanvasDestroy();
}

class FrostTerraRender extends SurfaceView implements SurfaceHolder.Callback{
    private SurfaceHolder mSurfaceHolder;
    private FrostTerraDrawingThread mThread;
    private Paint mPaint;
    private FrostTerraRenderClass mrenderclass;

    public FrostTerraRender(Context pContext, FrostTerraRenderClass mrc)
    {
        super(pContext);
        mSurfaceHolder = getHolder();
        mSurfaceHolder.addCallback(this);
        mThread = new FrostTerraDrawingThread();

        mPaint = new Paint();
        mPaint.setStyle(Paint.Style.FILL);
        mrenderclass = mrc;
    }

    public static Bitmap getBitmapFromAsset(Context context, String filePath) {
        AssetManager assetManager = context.getAssets();

        InputStream istr;
        Bitmap bitmap = null;
        try {
            istr = assetManager.open(filePath);
            bitmap = BitmapFactory.decodeStream(istr);
        } catch (IOException e) {
            e.printStackTrace();
        }

        return bitmap;
    }

    @Override
    protected void onDraw(Canvas pCanvas) {
        mrenderclass.onDraw(pCanvas,mPaint);
    }

    @Override
    public void surfaceCreated(SurfaceHolder surfaceHolder) {
        mThread.keepDrawing = true;
        mThread.start();
        mrenderclass.onCanvasChange(new FrostTerraRect(0,0,getWidth(),getHeight()));
    }

    @Override
    public void surfaceChanged(SurfaceHolder surfaceHolder, int i, int i1, int i2) {
        mrenderclass.onCanvasChange(new FrostTerraRect(0,0,i1,i2));
    }

    @Override
    public void surfaceDestroyed(SurfaceHolder surfaceHolder) {
        mrenderclass.onCanvasDestroy();
        mThread.keepDrawing = false;
        boolean retry = true;
        while (retry) {
            try {
                mThread.join();
                retry = false;
            } catch (InterruptedException e) {}
        }
    }

    private class FrostTerraDrawingThread extends Thread {
        boolean keepDrawing = true;

        @Override
        public void run() {
            Canvas canvas;
            while (keepDrawing) {
                canvas = null;
                try {
                    canvas = mSurfaceHolder.lockCanvas();
                    synchronized (mSurfaceHolder) {
                        long l = System.currentTimeMillis();
                        mrenderclass.onDraw(canvas,mPaint);
                        //System.out.println("D : " + (System.currentTimeMillis()-l));
                        // onDraw(canvas);
                    }
                } finally {
                    if (canvas != null)
                        mSurfaceHolder.unlockCanvasAndPost(canvas);
                }

                // Pour dessiner à 50 fps
                try {
                    Thread.sleep(20);
                } catch (InterruptedException e) {}
            }
        }
    }
}

class FrostTerraWorldScene
{
    private Bitmap m_world;
    private Canvas m_canvas;
    private FrostTerraRect m_size;
    private Rect m_src;
    private Rect m_dst;
    private FrostTerraCamera m_camera;
    private boolean use_cam = false;

    public FrostTerraWorldScene(Activity ac, Context c, FrostTerraRect size)
    {
        m_world = Bitmap.createBitmap(size.w,size.h,Bitmap.Config.ARGB_8888);
        m_canvas = new Canvas(m_world);
        m_src = new Rect(0,0,size.w,size.h);
        m_dst = new Rect(0,0,size.w,size.h);
        m_size = size;
    }

    public void attachCamera(FrostTerraCamera c)
    {
        m_camera = c;
        use_cam=true;
    }

    public void setBackground(FrostTerraColor c)
    {
        int color = Color.rgb(c.red(),c.green(),c.blue());
        m_canvas.drawColor(color);
    }

    public void drawCircle(FrostTerraRect object, Paint p)
    {
        m_canvas.drawCircle(object.x,object.y,object.w,p);
    }

    public void drawRect(int x, int y, int x2, int y2, Paint c)
    {
        m_canvas.drawRect(new Rect(x,y,(x2-x),(y2-y)),c);
    }

    public void drawRect(FrostTerraRect sap, Paint c)
    {
        drawRect(sap.x,sap.y,(sap.x+sap.w), (sap.y+sap.h), c);
    }


    public void drawImage(FrostTerraImage img, Paint c)
    {
        img.drawImage(m_canvas,c);
    }

    public void clear(FrostTerraColor c)
    {
        int color = Color.rgb(c.red(),c.green(),c.blue());
        m_canvas.drawColor(color, PorterDuff.Mode.CLEAR);
    }

    public void clear()
    {
        clear(new FrostTerraColor(FrostTerraColor.WHITE));
    }

    public void draw_world(Canvas c, Paint p)
    {
        if(use_cam)
        {
            m_src = new Rect(m_camera.getSizeViewOnWorld().x,m_camera.getSizeViewOnWorld().y,m_camera.getSizeViewOnWorld().w, m_camera.getSizeViewOnWorld().h);
            m_dst = new Rect(0,0,m_camera.getSizeViewOnScreen().w, m_camera.getSizeViewOnScreen().h);
        }
        c.drawBitmap(m_world,m_src,m_dst,p);
    }
}

class FrostTerraImage
{
    private Bitmap m_img;
    private FrostTerraRect m_pos;
    private FrostTerraRect m_src;

    public FrostTerraImage(Context c, String path, FrostTerraRect src, FrostTerraRect pos)
    {
        Bitmap temp = FrostTerraRender.getBitmapFromAsset(c, path);

        if(temp.getWidth() != pos.w || temp.getHeight() != pos.h) {
            m_img = Bitmap.createScaledBitmap(temp, pos.w, pos.h, true);
        }
        else
        {
            m_img = temp;
        }
        m_pos = pos;
        m_src= src;

    }

    public void setPosition(FrostTerraRect c)
    {
        m_pos = c;
    }

    public FrostTerraRect getPosition()
    {
        return m_pos;
    }

    public void setView(FrostTerraRect v)
    {
        m_src = v;
    }

    public FrostTerraRect getView()
    {
        return m_src;
    }

    public void drawImage(Canvas c, Paint p)
    {
        c.drawBitmap(m_img,new Rect(m_src.x,m_src.y,m_src.w,m_src.h), new Rect(m_pos.x,m_pos.y,(m_pos.x+m_pos.w),(m_pos.y+m_pos.h)),p);
    }

    public boolean isImageTouch(int x, int y)
    {
        if(x > m_pos.x && y > m_pos.y && x < (m_pos.x+m_pos.w) && y < (m_pos.y+m_pos.h))
        {
            return true;
        }
        return false;
    }
}

class FrostTerraCamera
{
    private FrostTerraRect m_viewscreen;
    private FrostTerraRect m_viewworld;

    public FrostTerraCamera(FrostTerraRect size_world, FrostTerraRect size_screen)
    {
        m_viewscreen = new FrostTerraRect(0,0,size_screen.w,size_screen.h);
        m_viewworld = new FrostTerraRect(0,0,size_world.w,size_world.h);
    }

    public void moveCamera(FrostTerraMove m)
    {
        m_viewworld.x = m_viewworld.x + m.getMoveX();
        m_viewworld.w = m_viewworld.w + m.getMoveX();
        m_viewworld.y = m_viewworld.y + m.getMoveY();
        m_viewworld.h = m_viewworld.h + m.getMoveY();
    }

    public void setPositionCamera(FrostTerraRect r)
    {
        m_viewworld.x = r.x;
        //m_viewscreen.w = m_viewscreen.w + r.x;
        m_viewworld.y = r.y;
        //m_viewscreen.h = m_viewscreen.h + r.y;
    }

    public FrostTerraRect getSizeViewOnWorld()
    {
        return m_viewworld;
    }

    public FrostTerraRect getSizeViewOnScreen()
    {
        return m_viewscreen;
    }
}

class FrostTerraText
{
    private String txt;
    private FrostTerraRect m_pos;
    private int size;
    private FrostTerraColor m_color;

    public FrostTerraText(String text, FrostTerraRect pos, int s, FrostTerraColor c)
    {
        txt=text;
        m_pos=pos;
        size=s;
        m_color=c;
    }

    public void setText(String t)
    {
        txt=t;
    }

    public String getText()
    {
        return txt;
    }

    public void setPos(FrostTerraRect r)
    {
        m_pos=r;
    }

    public FrostTerraRect getPos()
    {
        return m_pos;
    }

    public void setSize(int a)
    {
        size=a;
    }

    public int getSize()
    {
        return size;
    }

    public void setColor(FrostTerraColor c)
    {
        m_color=c;
    }

    public FrostTerraColor getColor()
    {
        return m_color;
    }

    public void drawText(Canvas c, Paint p)
    {
        drawText(c,this.txt,this.m_pos.x,this.m_pos.y,this.size,this.m_color,p);
    }

    public static void drawText(Canvas ca, String s, int x, int y, int si, FrostTerraColor c, Paint p)
    {
        int color = Color.rgb(c.red(),c.green(),c.blue());
        int tmp=p.getColor();
        p.setColor(color);
        p.setTextSize(si);
        ca.drawText(s,x,y,p);
        p.setColor(tmp);
    }

    public static int SizeText(Paint p, String text)
    {
        int l = text.length();
        float w[] = new float[l];
        p.getTextWidths(text,w);
        float f=0;
        for(int i=0;i<l;i++)
        {
            f=f+w[i];
        }

        return (int)f;
    }
}

class FrostTerraSoundSettings
{
    private int m_max_stream;
    private AudioAttributes m_audio_att;

    public FrostTerraSoundSettings(int max_stream, int content, int flags, int lst, int usage)
    {
        m_max_stream=max_stream;
        m_audio_att = new AudioAttributes.Builder().setContentType(content).setFlags(flags).setLegacyStreamType(lst).setUsage(usage).build();
    }

    public int getM_max_stream()
    {
        return m_max_stream;
    }

    public AudioAttributes getM_audio_att()
    {
        return m_audio_att;
    }
}

class FrostTerraSound
{
    private SoundPool m_player;
    private Context m_context;
    private ArrayMap<String,Integer> m_array_sound;

    public FrostTerraSound(Context context, FrostTerraSoundSettings audio_setting)
    {
        m_player = new SoundPool.Builder().setMaxStreams(audio_setting.getM_max_stream()).setAudioAttributes(audio_setting.getM_audio_att()).build();
        m_context = context;
        m_array_sound = new ArrayMap<>();
    }

    public void loadSound(String id, int resID)
    {
        int id_int = m_player.load(m_context,resID,1);
        m_array_sound.put(id,id_int);
    }

    public void playSound(String id, int leftv, int rightv, int priority, int loop, int rate)
    {
        int iid = m_array_sound.get(id);
        m_player.play(iid,leftv,rightv,priority,loop,rate);
    }

    public void pauseSound(String id)
    {
        int iid = m_array_sound.get(id);
        m_player.pause(iid);
    }

    public void resumeSound(String id)
    {
        int iid = m_array_sound.get(id);
        m_player.resume(iid);
    }

    public void stopSound(String id)
    {
        int iid = m_array_sound.get(id);
        m_player.stop(iid);
    }

    public void releaseClass()
    {
        m_player.release();
    }
}

interface FrostTerraEventListener
{
    public void onTouch(int x, int y, float pressure);
}

class FrostTerraEvent implements View.OnTouchListener
{
    private FrostTerraEventListener m_callable;

    public FrostTerraEvent(FrostTerraEventListener callable)
    {
        m_callable=callable;
    }

    @Override
    public boolean onTouch(View view, MotionEvent motionEvent) {
        m_callable.onTouch((int)motionEvent.getX(),(int)motionEvent.getY(),motionEvent.getPressure());
        return true;
    }
}

interface FrostTerraSensor
{
    public void init_sensor(SensorManager m);
    public SensorEventListener getSensorListener();
    public Sensor getSensor();
}

interface FrostTerraSensorListener
{
    public void onSendData(String data);
}

class FrostTerraManagerSensor
{
    private SensorManager mManager = null;
    private ArrayMap<String,Integer> m_array_isensor;
    private FrostTerraSensor m_array_sensor[];
    private int current_array_sensor = 0;

    public static final int MAX_SENSORS = 5;

    public FrostTerraManagerSensor(Context c)
    {
        mManager = (SensorManager)c.getSystemService(Service.SENSOR_SERVICE);
        m_array_isensor = new ArrayMap<>();
        m_array_sensor = new FrostTerraSensor[MAX_SENSORS];
    }

    public void appendSensor(String id, FrostTerraSensor s)
    {
        if(current_array_sensor<MAX_SENSORS)
        {
            s.init_sensor(mManager);
            m_array_sensor[current_array_sensor] = s;
            m_array_isensor.put(id,current_array_sensor);
            startSensor(id);
            current_array_sensor++;
        }
    }

    public void stopSensor(String id)
    {
        int idc = m_array_isensor.get(id);
        mManager.unregisterListener(m_array_sensor[idc].getSensorListener(), m_array_sensor[idc].getSensor());
    }

    public void startSensor(String id)
    {
        int idc = m_array_isensor.get(id);
        mManager.registerListener(m_array_sensor[idc].getSensorListener(), m_array_sensor[idc].getSensor(), SensorManager.SENSOR_DELAY_GAME);
    }
}

class FrostTerraAccelerometer implements FrostTerraSensor, SensorEventListener
{
    private FrostTerraSensorListener m_sensor_listener = null;
    private Sensor mAccelerometre = null;

    public FrostTerraAccelerometer(FrostTerraSensorListener sl)
    {
        m_sensor_listener=sl;
    }

    @Override
    public void init_sensor(SensorManager m) {
        mAccelerometre = m.getDefaultSensor(Sensor.TYPE_ACCELEROMETER);
    }

    @Override
    public SensorEventListener getSensorListener() {
        return this;
    }

    @Override
    public Sensor getSensor() {
        return mAccelerometre;
    }


    @Override
    public void onSensorChanged(SensorEvent sensorEvent) {
        float x = sensorEvent.values[0];
        float y = sensorEvent.values[1];
        String user_agent = "(C=ACC)/X="+x+"/Y="+y;
        m_sensor_listener.onSendData(user_agent);
    }

    @Override
    public void onAccuracyChanged(Sensor sensor, int i) {

    }
}

class FrostTerraRect
{
    public int x;
    public int y;
    public int w;
    public int h;

    public FrostTerraRect()
    {
        x=0;
        y=0;
        w=0;
        h=0;
    }

    public FrostTerraRect(int a, int b)
    {
        x=a;
        y=b;
        w=0;
        h=0;
    }

    public FrostTerraRect(int a, int b, int c, int d)
    {
        x=a;
        y=b;
        w=c;
        h=d;
    }
}

class FrostTerraColor
{
    private int a;
    private int r;
    private int g;
    private int b;

    public final static int RED = 1;
    public final static int GREEN = 2;
    public final static int BLUE = 3;
    public final static int BLACK = 4;
    public final static int WHITE = 5;

    public FrostTerraColor(int id)
    {
        switch(id)
        {
            case RED:
                a=0;
                r=255;
                g=0;
                b=0;
                break;
            case GREEN:
                a=0;
                r=0;
                g=255;
                b=0;
                break;
            case BLUE:
                a=0;
                r=0;
                g=0;
                b=255;
                break;
            case WHITE:
                a=0;
                r=255;
                b=255;
                g=255;
                break;
            case BLACK:
                a=0;
                r=0;
                b=0;
                g=0;
                break;
        }
    }

    public FrostTerraColor(int a1, int b, int c, int db)
    {
        a=a1;
        r=b;
        g=c;
        b=db;
    }

    public int alpha()
    {
        return a;
    }

    public int red()
    {
        return r;
    }

    public int green()
    {
        return g;
    }

    public int blue()
    {
        return b;
    }
}

class FrostTerraMove
{
    private int m_move_x;
    private int m_move_y;

    public FrostTerraMove(int move_x, int move_y)
    {
        m_move_x = move_x;
        m_move_y = move_y;
    }

    public int getMoveX()
    {
        return m_move_x;
    }

    public int getMoveY()
    {
        return m_move_y;
    }
}

interface FrostTerraAlarmCatch
{
    public void catch_signal();
}

class FrostTerraAlarm extends Thread
{
    private Thread t;
    private String threadName;
    private int time_sec;
    private FrostTerraAlarmCatch mc;

    public FrostTerraAlarm(String name, int tn, FrostTerraAlarmCatch cn)
    {
        threadName=name;
        time_sec=tn;
        mc=cn;
    }

    @Override
    public void run()
    {
        try {
            Thread.sleep((time_sec*1000));
        } catch (InterruptedException e) {e.printStackTrace();}
        mc.catch_signal();
    }

    @Override
    public void start () {
        if (t == null) {
            t = new Thread (this, threadName);
            t.start ();
        }
    }
}
