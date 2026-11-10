// Animate only the water in the photographed scene. The CSS image remains a
// complete fallback when WebGL is unavailable, lost, or motion is reduced.
export function setupOcean(canvas, motionAllowed) {
  const gl = canvas?.getContext('webgl', { alpha: false, antialias: false, depth: false, powerPreference: 'low-power' });
  if (!gl) return { sync() {}, destroy() {} };

  const vertexSource = `
    attribute vec2 position;
    void main() { gl_Position = vec4(position, 0.0, 1.0); }
  `;
  const fragmentSource = `
    precision mediump float;
    uniform sampler2D ocean;
    uniform vec2 resolution;
    uniform float imageAspect;
    uniform float focus;
    uniform float time;
    void main() {
      vec2 screen = vec2(gl_FragCoord.x / resolution.x, 1.0 - gl_FragCoord.y / resolution.y);
      float aspect = resolution.x / resolution.y;
      vec2 cover = vec2(min(1.0, aspect / imageAspect), min(1.0, imageAspect / aspect));
      vec2 uv = screen * cover + vec2((1.0 - cover.x) * focus, (1.0 - cover.y) * 0.5);
      float water = smoothstep(0.448, 0.469, uv.y);
      float depth = clamp((uv.y - 0.45) / 0.55, 0.0, 1.0);
      vec2 displaced = uv;
      displaced.x += water * (0.3 + depth) * (
        sin(uv.y * 47.0 - time * 0.65 + sin(uv.x * 18.0 + time * 0.16)) * 0.0038
        + sin(uv.y * 113.0 + uv.x * 28.0 - time * 0.9) * 0.0015);
      displaced.y += water * depth * (
        sin(uv.x * 41.0 + uv.y * 53.0 - time * 0.72) * 0.0027
        + sin(uv.x * 77.0 - uv.y * 91.0 + time * 0.8) * 0.0012);
      vec3 color = texture2D(ocean, clamp(displaced, 0.001, 0.999)).rgb;
      float reflection = exp(-pow((uv.x - 0.747) / (0.025 + depth * 0.18), 2.0)) * water;
      float sparkle = pow(max(0.0, sin(uv.x * 173.0 + uv.y * 281.0 - time * 1.3)
        * sin(uv.x * 311.0 - uv.y * 183.0 + time * 0.9)), 14.0);
      float light = dot(color, vec3(0.299, 0.587, 0.114));
      color *= 1.0 + water * sin(uv.y * 86.0 + uv.x * 23.0 - time * 1.15) * 0.045;
      color += vec3(0.91, 0.89, 0.79) * reflection * sparkle * (0.025 + depth * 0.08);
      color += vec3(0.1, 0.14, 0.18) * light * reflection * (0.5 + 0.5 * sin(uv.y * 117.0 - time));
      gl_FragColor = vec4(color, 1.0);
    }
  `;

  let frame = 0;
  let previous = 0;
  let elapsed = 0;
  let ready = false;
  let destroyed = false;
  let program;
  let buffer;
  let texture;
  const shaders = [];
  let uniforms;
  const picture = new Image();

  function compile(type, source) {
    const shader = gl.createShader(type);
    shaders.push(shader);
    gl.shaderSource(shader, source);
    gl.compileShader(shader);
    if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) throw new Error('Water shader unavailable');
    return shader;
  }

  function draw() {
    if (!ready || destroyed || gl.isContextLost()) return;
    gl.uniform1f(uniforms.time, elapsed);
    gl.drawArrays(gl.TRIANGLES, 0, 6);
  }

  function resize() {
    if (!ready || destroyed) return;
    const ratio = Math.min(window.devicePixelRatio || 1, window.innerWidth < 700 ? 1 : 1.5);
    const width = Math.round(canvas.clientWidth * ratio);
    const height = Math.round(canvas.clientHeight * ratio);
    if (!width || !height) return;
    canvas.width = width;
    canvas.height = height;
    gl.viewport(0, 0, width, height);
    gl.uniform2f(uniforms.resolution, width, height);
    gl.uniform1f(uniforms.focus, Number.parseFloat(getComputedStyle(canvas).getPropertyValue('--ocean-focus')) || 0.54);
    draw();
  }

  function tick(now) {
    frame = 0;
    if (!ready || destroyed || !motionAllowed() || gl.isContextLost()) { previous = 0; return; }
    if (!previous) previous = now;
    const delta = now - previous;
    // 30fps is ample for slow water and halves the GPU work on mobile.
    if (delta >= 1000 / 30) {
      elapsed += Math.min(delta, 80) / 1000;
      previous = now;
      draw();
    }
    frame = requestAnimationFrame(tick);
  }

  function sync() {
    if (!ready || destroyed) return;
    if (motionAllowed() && !frame) frame = requestAnimationFrame(tick);
    else if (!motionAllowed()) {
      cancelAnimationFrame(frame);
      frame = 0;
      previous = 0;
    }
  }

  function lost() {
    ready = false;
    cancelAnimationFrame(frame);
    canvas.classList.remove('is-ready');
  }

  picture.onload = () => {
    if (destroyed) return;
    try {
      program = gl.createProgram();
      gl.attachShader(program, compile(gl.VERTEX_SHADER, vertexSource));
      gl.attachShader(program, compile(gl.FRAGMENT_SHADER, fragmentSource));
      gl.linkProgram(program);
      if (!gl.getProgramParameter(program, gl.LINK_STATUS)) throw new Error('Water shader unavailable');
      gl.useProgram(program);
      buffer = gl.createBuffer();
      gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
      gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([-1,-1, 1,-1, -1,1, -1,1, 1,-1, 1,1]), gl.STATIC_DRAW);
      const position = gl.getAttribLocation(program, 'position');
      gl.enableVertexAttribArray(position);
      gl.vertexAttribPointer(position, 2, gl.FLOAT, false, 0, 0);
      texture = gl.createTexture();
      gl.bindTexture(gl.TEXTURE_2D, texture);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
      gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGB, gl.RGB, gl.UNSIGNED_BYTE, picture);
      uniforms = Object.fromEntries(['time', 'resolution', 'imageAspect', 'focus'].map(name => [name, gl.getUniformLocation(program, name)]));
      gl.uniform1i(gl.getUniformLocation(program, 'ocean'), 0);
      gl.uniform1f(uniforms.imageAspect, picture.naturalWidth / picture.naturalHeight);
      ready = true;
      resize();
      canvas.classList.add('is-ready');
      sync();
    } catch {
      lost();
    }
  };

  const sizeObserver = new ResizeObserver(resize);
  sizeObserver.observe(canvas);
  canvas.addEventListener('webglcontextlost', lost);
  picture.src = `${import.meta.env.BASE_URL}images/moonlit-ocean.webp`;

  return {
    sync,
    destroy() {
      destroyed = true;
      cancelAnimationFrame(frame);
      sizeObserver.disconnect();
      canvas.removeEventListener('webglcontextlost', lost);
      picture.onload = null;
      for (const shader of shaders) gl.deleteShader(shader);
      if (texture) gl.deleteTexture(texture);
      if (buffer) gl.deleteBuffer(buffer);
      if (program) gl.deleteProgram(program);
    },
  };
}
